#!/usr/bin/env python3

import argparse
import re
import sys
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
