#!/usr/bin/env python3

import argparse
import hashlib
import re
import shutil
import sys
import zipfile
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
VERSION_SOURCE = ROOT / "src" / "scripting" / "hns" / "version.inc"

SEMVER_IDENTIFIER = r"(?:0|[1-9][0-9]*|[0-9]*[A-Za-z-][0-9A-Za-z-]*)"
SEMVER_PATTERN = re.compile(
  rf"^(?P<major>0|[1-9][0-9]*)"
  rf"\.(?P<minor>0|[1-9][0-9]*)"
  rf"\.(?P<patch>0|[1-9][0-9]*)"
  rf"(?:-(?P<prerelease>{SEMVER_IDENTIFIER}(?:\.{SEMVER_IDENTIFIER})*))?"
  r"(?:\+(?P<build>[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?$"
)
VERSION_DEFINE_PATTERN = re.compile(
  r'^\s*#define\s+HNS_VERSION\s+"([^"]+)"\s*$',
  flags=re.MULTILINE,
)


class ReleaseError(ValueError):
  pass


@dataclass(frozen=True)
class ReleaseArtifacts:
  archive: Path
  plugin: Path
  checksums: Path


def is_valid_semver(version: str) -> bool:
  return SEMVER_PATTERN.fullmatch(version) is not None


def is_prerelease(version: str) -> bool:
  match = SEMVER_PATTERN.fullmatch(version)
  if match is None:
    raise ReleaseError(f"Invalid SemVer version: {version!r}")
  return match.group("prerelease") is not None


def tag_matches_version(tag: str, version: str) -> bool:
  return is_valid_semver(version) and tag == f"v{version}"


def read_version(version_source: Path = VERSION_SOURCE) -> str:
  try:
    source = version_source.read_text(encoding="utf-8")
  except OSError as error:
    raise ReleaseError(f"Cannot read version source {version_source}: {error}") from error

  definitions = VERSION_DEFINE_PATTERN.findall(source)
  if len(definitions) != 1:
    raise ReleaseError(
      f"Expected exactly one HNS_VERSION definition in {version_source}, "
      f"found {len(definitions)}"
    )

  version = definitions[0]
  if not is_valid_semver(version):
    raise ReleaseError(f"HNS_VERSION is not valid SemVer 2.0.0: {version!r}")
  return version


def sha256_file(path: Path) -> str:
  digest = hashlib.sha256()
  with path.open("rb") as source:
    for chunk in iter(lambda: source.read(1024 * 1024), b""):
      digest.update(chunk)
  return digest.hexdigest()


def release_inputs(project_root: Path, plugin_path: Path) -> list[tuple[Path, str]]:
  resources = [
    (plugin_path, "addons/amxmodx/plugins/hns.amxx"),
    (
      project_root / "src" / "configs" / "hns.cfg",
      "addons/amxmodx/configs/hns.cfg",
    ),
    (
      project_root / "src" / "data" / "lang" / "hns.txt",
      "addons/amxmodx/data/lang/hns.txt",
    ),
  ]

  sound_root = project_root / "src" / "sound" / "hns"
  if not sound_root.is_dir():
    raise ReleaseError(f"Required sound directory is missing: {sound_root}")

  sound_files = sorted(path for path in sound_root.rglob("*") if path.is_file())
  if not sound_files:
    raise ReleaseError(f"Required sound directory is empty: {sound_root}")

  resources.extend(
    (
      path,
      f"sound/{path.relative_to(project_root / 'src' / 'sound').as_posix()}",
    )
    for path in sound_files
  )

  for source, _archive_path in resources:
    if not source.is_file():
      raise ReleaseError(f"Required release file is missing: {source}")

  return resources


def verify_archive(
  archive_path: Path,
  resources: list[tuple[Path, str]],
) -> None:
  expected_names = [archive_name for _source, archive_name in resources]
  try:
    with zipfile.ZipFile(archive_path) as archive:
      if archive.namelist() != expected_names:
        raise ReleaseError(
          f"Release archive file list does not match allowlist: {archive_path}"
        )

      for source, archive_name in resources:
        if archive.read(archive_name) != source.read_bytes():
          raise ReleaseError(
            f"Release archive content differs from source: {archive_name}"
          )
  except (OSError, zipfile.BadZipFile) as error:
    raise ReleaseError(f"Cannot verify release archive {archive_path}: {error}") from error


def package_release(
  plugin_path: Path,
  output_dir: Path,
  *,
  project_root: Path = ROOT,
) -> ReleaseArtifacts:
  project_root = project_root.resolve()
  plugin_path = plugin_path.resolve()
  output_dir = output_dir.absolute()
  version_source = project_root / "src" / "scripting" / "hns" / "version.inc"
  version = read_version(version_source)
  resources = release_inputs(project_root, plugin_path)

  archive_path = output_dir / f"hns-v{version}.zip"
  standalone_path = output_dir / "hns.amxx"
  checksums_path = output_dir / "SHA256SUMS"

  try:
    output_dir.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(
      archive_path,
      mode="w",
      compression=zipfile.ZIP_DEFLATED,
      compresslevel=9,
    ) as archive:
      for source, archive_name in resources:
        archive.writestr(archive_name, source.read_bytes())

    verify_archive(archive_path, resources)
    shutil.copyfile(plugin_path, standalone_path)

    checksums = (
      f"{sha256_file(archive_path)}  {archive_path.name}\n"
      f"{sha256_file(standalone_path)}  {standalone_path.name}\n"
    )
    checksums_path.write_text(checksums, encoding="ascii", newline="\n")
  except ReleaseError:
    raise
  except (OSError, zipfile.BadZipFile) as error:
    raise ReleaseError(f"Cannot build release package: {error}") from error

  return ReleaseArtifacts(
    archive=archive_path,
    plugin=standalone_path,
    checksums=checksums_path,
  )


def command_version(_args: argparse.Namespace) -> int:
  print(read_version())
  return 0


def command_verify_tag(args: argparse.Namespace) -> int:
  version = read_version()
  if not tag_matches_version(args.tag, version):
    raise ReleaseError(
      f"Release tag {args.tag!r} does not match source version {version!r}"
    )

  print(f"version={version}")
  print(f"tag={args.tag}")
  print(f"prerelease={'true' if is_prerelease(version) else 'false'}")
  return 0


def command_package(args: argparse.Namespace) -> int:
  artifacts = package_release(args.plugin, args.output_dir)
  print(artifacts.archive)
  print(artifacts.plugin)
  print(artifacts.checksums)
  return 0


def build_parser() -> argparse.ArgumentParser:
  parser = argparse.ArgumentParser(
    description="Validate and package Hide N Seek: Ultimate releases."
  )
  subparsers = parser.add_subparsers(dest="command", required=True)

  version_parser = subparsers.add_parser(
    "version",
    help="Print the SemVer version from the Pawn source.",
  )
  version_parser.set_defaults(handler=command_version)

  tag_parser = subparsers.add_parser(
    "verify-tag",
    help="Verify that a v<SemVer> Git tag matches the Pawn source.",
  )
  tag_parser.add_argument("--tag", required=True, help="Git tag to verify")
  tag_parser.set_defaults(handler=command_verify_tag)

  package_parser = subparsers.add_parser(
    "package",
    help="Build installable release assets from a compiled hns.amxx.",
  )
  package_parser.add_argument(
    "--plugin",
    required=True,
    type=Path,
    help="Path to the freshly compiled hns.amxx",
  )
  package_parser.add_argument(
    "--output-dir",
    required=True,
    type=Path,
    help="Directory for release assets",
  )
  package_parser.set_defaults(handler=command_package)

  return parser


def main(argv: list[str] | None = None) -> int:
  parser = build_parser()
  args = parser.parse_args(argv)

  try:
    return args.handler(args)
  except ReleaseError as error:
    print(f"error: {error}", file=sys.stderr)
    return 1


if __name__ == "__main__":
  raise SystemExit(main())
