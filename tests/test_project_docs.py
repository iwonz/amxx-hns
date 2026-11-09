import re
import unittest
from pathlib import Path


ROOT = Path(__file__).parents[1]
SOURCE = (ROOT / "src" / "scripting" / "hns.sma").read_text(encoding="utf-8")
README = (ROOT / "README.md").read_text(encoding="utf-8")
AGENTS = (ROOT / "AGENTS.md").read_text(encoding="utf-8")
SPEC_FILES = sorted((ROOT / "openspec" / "specs").glob("*/spec.md"))
SPECS = "\n".join(path.read_text(encoding="utf-8") for path in SPEC_FILES)


class ProjectDocumentationTests(unittest.TestCase):
  def test_every_registered_cvar_is_documented_for_users_and_in_specs(self):
    cvars = set(re.findall(r'register_cvar\("([^"]+)"', SOURCE))

    self.assertGreater(len(cvars), 0)
    for cvar in sorted(cvars):
      self.assertIn(f"`{cvar}`", README, f"README does not document {cvar}")
      self.assertIn(f"`{cvar}`", SPECS, f"OpenSpec does not document {cvar}")

  def test_openspec_capabilities_have_requirements_and_scenarios(self):
    expected_capabilities = {
      "configuration-and-localization",
      "core-boundaries",
      "equipment-and-map-rules",
      "fall-damage-and-recovery",
      "flashbang-rules",
      "round-lifecycle",
      "team-and-player-flow",
    }

    self.assertEqual(expected_capabilities, {path.parent.name for path in SPEC_FILES})

    for path in SPEC_FILES:
      content = path.read_text(encoding="utf-8")
      self.assertIn("## Requirements", content, path)
      self.assertRegex(content, r"(?m)^### Requirement: .+$", path)
      self.assertRegex(content, r"(?m)^#### Scenario: .+$", path)

  def test_agent_guidance_requires_openspec_and_verification(self):
    for required_text in (
      "openspec validate --all --strict",
      "python3 -B -m unittest discover -s tests -v",
      "src/configs/hns.cfg",
      "CP1251",
      "hns.txt",
      "OpenSpec workflow",
    ):
      self.assertIn(required_text, AGENTS)

  def test_readme_installation_references_every_deployable_resource(self):
    for required_path in (
      "addons/amxmodx/plugins/hns.amxx",
      "addons/amxmodx/configs/hns.cfg",
      "addons/amxmodx/data/lang/hns.txt",
      "sound/hns",
      "plugins.ini",
      "modules.ini",
    ):
      self.assertIn(required_path, README)

  def test_readme_local_links_resolve(self):
    links = re.findall(r"\[[^]]+\]\(([^)]+)\)", README)

    self.assertGreater(len(links), 0)
    for link in links:
      if "://" in link or link.startswith("#"):
        continue
      self.assertTrue((ROOT / link).exists(), f"Broken README link: {link}")


if __name__ == "__main__":
  unittest.main()
