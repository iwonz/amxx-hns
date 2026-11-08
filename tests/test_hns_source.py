import re
import unittest
from pathlib import Path


SOURCE_PATH = Path(__file__).parents[1] / "src" / "scripting" / "hns.sma"
SOURCE = SOURCE_PATH.read_text(encoding="utf-8")


def function_body(name: str) -> str:
  match = re.search(rf"\b{name}\s*\([^)]*\)\s*\{{", SOURCE)
  if not match:
    raise AssertionError(f"Function {name} was not found")

  opening_brace = SOURCE.index("{", match.start())
  depth = 0

  for index in range(opening_brace, len(SOURCE)):
    if SOURCE[index] == "{":
      depth += 1
    elif SOURCE[index] == "}":
      depth -= 1
      if depth == 0:
        return SOURCE[opening_brace + 1:index]

  raise AssertionError(f"Function {name} has no closing brace")


class HnsSourceRegressionTests(unittest.TestCase):
  def test_play_only_restores_afk_spectators_to_playable_team(self):
    body = function_body("fnSayPlay")
    guard = "if(get_user_team(id) != 3 || !fnIsPlayableTeam(g_aIsAfkTeam[id]))"
    team_change = "cs_set_user_team(id, g_aIsAfkTeam[id]);"

    self.assertIn("bool:fnIsPlayableTeam", SOURCE)
    self.assertIn(guard, body)
    self.assertLess(body.index(guard), body.index(team_change))


if __name__ == "__main__":
  unittest.main()
