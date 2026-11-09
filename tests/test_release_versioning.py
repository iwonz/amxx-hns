import hashlib
import importlib.util
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
import zipfile
from functools import lru_cache
from pathlib import Path


ROOT = Path(__file__).parents[1]
RELEASE_SCRIPT = ROOT / "scripts" / "release.py"
VERSION_SOURCE = ROOT / "src" / "scripting" / "hns" / "version.inc"
HNS_SOURCE = ROOT / "src" / "scripting" / "hns.sma"


@lru_cache(maxsize=1)
def load_release_module():
  if not RELEASE_SCRIPT.is_file():
    raise AssertionError(f"Release helper is missing: {RELEASE_SCRIPT}")

  spec = importlib.util.spec_from_file_location("hns_release", RELEASE_SCRIPT)
  if spec is None or spec.loader is None:
    raise AssertionError(f"Cannot load release helper: {RELEASE_SCRIPT}")

  module = importlib.util.module_from_spec(spec)
  sys.modules[spec.name] = module
  spec.loader.exec_module(module)
  return module


class ReleaseVersioningTests(unittest.TestCase):
  def test_hns_plugin_uses_one_pawn_version_source(self):
    self.assertTrue(VERSION_SOURCE.is_file(), "Pawn version source is missing")

    version_source = VERSION_SOURCE.read_text(encoding="utf-8")
    version_definitions = re.findall(
      r'^\s*#define\s+HNS_VERSION\s+"([^"]+)"\s*$',
      version_source,
      flags=re.MULTILINE,
    )
    hns_source = HNS_SOURCE.read_text(encoding="utf-8")

    self.assertEqual(["1.0.0"], version_definitions)
    self.assertIn('#include "hns/version.inc"', hns_source)
    self.assertIn("register_plugin(PLUGIN, HNS_VERSION, AUTHOR);", hns_source)
    self.assertNotRegex(hns_source, r'^\s*#define\s+VERSION\s+"',)

  def test_full_semver_versions_are_accepted(self):
    release = load_release_module()

    for version in (
      "0.0.0",
      "1.2.3",
      "2.0.0-rc.1",
      "2.0.0-rc.1+build.7",
      "10.20.30-alpha.beta+linux.x86",
    ):
      with self.subTest(version=version):
        self.assertTrue(release.is_valid_semver(version))

  def test_non_semver_versions_are_rejected(self):
    release = load_release_module()

    for version in (
      "",
      "1",
      "1.0",
      "v1.0.0",
      "01.0.0",
      "1.01.0",
      "1.0.01",
      "1.0.0-01",
      "1.0.0-",
      "1.0.0+",
      "1.0.0 beta",
    ):
      with self.subTest(version=version):
        self.assertFalse(release.is_valid_semver(version))

  def test_release_tag_must_exactly_match_version(self):
    release = load_release_module()

    self.assertTrue(release.tag_matches_version("v1.0.0", "1.0.0"))
    self.assertTrue(
      release.tag_matches_version(
        "v2.0.0-rc.1+build.7",
        "2.0.0-rc.1+build.7",
      )
    )
    self.assertFalse(release.tag_matches_version("1.0.0", "1.0.0"))
    self.assertFalse(release.tag_matches_version("v1.0.1", "1.0.0"))
    self.assertFalse(release.tag_matches_version("v01.0.0", "01.0.0"))

  def test_prerelease_detection_ignores_build_metadata(self):
    release = load_release_module()

    self.assertFalse(release.is_prerelease("1.0.0"))
    self.assertFalse(release.is_prerelease("1.0.0+build.7"))
    self.assertTrue(release.is_prerelease("1.0.0-rc.1"))
    self.assertTrue(release.is_prerelease("1.0.0-rc.1+build.7"))

  def test_version_command_reads_pawn_source(self):
    result = subprocess.run(
      [sys.executable, str(RELEASE_SCRIPT), "version"],
      cwd=ROOT,
      capture_output=True,
      text=True,
      check=False,
    )

    self.assertEqual(0, result.returncode, result.stderr)
    self.assertEqual("1.0.0", result.stdout.strip())

  def test_verify_tag_command_fails_closed_on_mismatch(self):
    matching = subprocess.run(
      [
        sys.executable,
        str(RELEASE_SCRIPT),
        "verify-tag",
        "--tag",
        "v1.0.0",
      ],
      cwd=ROOT,
      capture_output=True,
      text=True,
      check=False,
    )
    mismatching = subprocess.run(
      [
        sys.executable,
        str(RELEASE_SCRIPT),
        "verify-tag",
        "--tag",
        "v1.0.1",
      ],
      cwd=ROOT,
      capture_output=True,
      text=True,
      check=False,
    )

    self.assertEqual(0, matching.returncode, matching.stderr)
    self.assertIn("version=1.0.0", matching.stdout)
    self.assertIn("prerelease=false", matching.stdout)
    self.assertNotEqual(0, mismatching.returncode)
    self.assertIn("does not match", mismatching.stderr)

  def test_package_contains_exact_deployable_tree_and_checksums(self):
    release = load_release_module()
    package_release = getattr(release, "package_release", None)
    self.assertIsNotNone(package_release, "package_release() is missing")

    with tempfile.TemporaryDirectory() as temp_dir:
      temp_path = Path(temp_dir)
      plugin_path = temp_path / "compiled" / "hns.amxx"
      output_dir = temp_path / "release"
      plugin_bytes = b"compiled-amxx\x00\xff"
      plugin_path.parent.mkdir(parents=True)
      plugin_path.write_bytes(plugin_bytes)

      artifacts = package_release(plugin_path, output_dir, project_root=ROOT)

      archive_path = output_dir / "hns-v1.0.0.zip"
      standalone_path = output_dir / "hns.amxx"
      checksums_path = output_dir / "SHA256SUMS"
      self.assertEqual(archive_path, artifacts.archive)
      self.assertEqual(standalone_path, artifacts.plugin)
      self.assertEqual(checksums_path, artifacts.checksums)
      self.assertEqual(plugin_bytes, standalone_path.read_bytes())

      expected_files = {
        "addons/amxmodx/plugins/hns.amxx",
        "addons/amxmodx/configs/hns.cfg",
        "addons/amxmodx/data/lang/hns.txt",
      }
      expected_files.update(
        f"sound/{path.relative_to(ROOT / 'src' / 'sound').as_posix()}"
        for path in (ROOT / "src" / "sound" / "hns").rglob("*")
        if path.is_file()
      )

      with zipfile.ZipFile(archive_path) as archive:
        self.assertEqual(expected_files, set(archive.namelist()))
        self.assertEqual(
          plugin_bytes,
          archive.read("addons/amxmodx/plugins/hns.amxx"),
        )
        self.assertEqual(
          (ROOT / "src" / "configs" / "hns.cfg").read_bytes(),
          archive.read("addons/amxmodx/configs/hns.cfg"),
        )
        self.assertEqual(
          (ROOT / "src" / "data" / "lang" / "hns.txt").read_bytes(),
          archive.read("addons/amxmodx/data/lang/hns.txt"),
        )

      expected_checksums = (
        f"{hashlib.sha256(archive_path.read_bytes()).hexdigest()}  "
        f"{archive_path.name}\n"
        f"{hashlib.sha256(standalone_path.read_bytes()).hexdigest()}  "
        f"{standalone_path.name}\n"
      )
      self.assertEqual(expected_checksums, checksums_path.read_text(encoding="ascii"))

  def test_package_fails_when_required_resource_is_missing(self):
    release = load_release_module()
    package_release = getattr(release, "package_release", None)
    self.assertIsNotNone(package_release, "package_release() is missing")

    with tempfile.TemporaryDirectory() as temp_dir:
      temp_path = Path(temp_dir)
      project_root = temp_path / "project"
      output_dir = temp_path / "release"
      plugin_path = temp_path / "hns.amxx"
      plugin_path.write_bytes(b"compiled-amxx")

      version_target = project_root / "src" / "scripting" / "hns" / "version.inc"
      version_target.parent.mkdir(parents=True)
      shutil.copyfile(VERSION_SOURCE, version_target)

      lang_target = project_root / "src" / "data" / "lang" / "hns.txt"
      lang_target.parent.mkdir(parents=True)
      shutil.copyfile(ROOT / "src" / "data" / "lang" / "hns.txt", lang_target)

      sound_target = project_root / "src" / "sound" / "hns"
      sound_target.parent.mkdir(parents=True)
      shutil.copytree(ROOT / "src" / "sound" / "hns", sound_target)

      with self.assertRaisesRegex(release.ReleaseError, "hns.cfg"):
        package_release(plugin_path, output_dir, project_root=project_root)

      self.assertFalse(output_dir.exists())

  def test_package_command_builds_release_assets(self):
    with tempfile.TemporaryDirectory() as temp_dir:
      temp_path = Path(temp_dir)
      plugin_path = temp_path / "hns.amxx"
      output_dir = temp_path / "release"
      plugin_path.write_bytes(b"compiled-amxx")

      result = subprocess.run(
        [
          sys.executable,
          str(RELEASE_SCRIPT),
          "package",
          "--plugin",
          str(plugin_path),
          "--output-dir",
          str(output_dir),
        ],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
      )

      self.assertEqual(0, result.returncode, result.stderr)
      self.assertTrue((output_dir / "hns-v1.0.0.zip").is_file())
      self.assertTrue((output_dir / "hns.amxx").is_file())
      self.assertTrue((output_dir / "SHA256SUMS").is_file())


if __name__ == "__main__":
  unittest.main()
