"""Focused archive-policy tests that avoid building the production release."""
import importlib.util
import hashlib
from pathlib import Path
import tempfile
import unittest
import zipfile


PACKAGER = Path(__file__).with_name("package_release.py")
SPEC = importlib.util.spec_from_file_location("package_release", PACKAGER)
package_release = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(package_release)


class SourceArchivePolicyTests(unittest.TestCase):
    def _write(self, project: Path, relative: str, contents: str = "x") -> None:
        file = project / relative
        file.parent.mkdir(parents=True, exist_ok=True)
        file.write_text(contents, encoding="utf-8")

    def _fixture_project(self, root: Path) -> Path:
        project = root / "project"
        self._write(project, "game/project.godot", "[application]\nconfig/name=\"Fixture\"\n")
        self._write(project, "game/scenes/main.tscn")
        self._write(project, "docs/licenses/GODOT_THIRD_PARTY.txt", "notice")
        for pack in package_release.REQUIRED_SOURCE_PACKS:
            self._write(project, f"source_art/{pack}/production.png")
        self._write(project, "source_art/Pac_Man_One_Eye_Runtime_Overrides/canonical.png")
        self._write(project, "source_art/Pac_Man_One_Eye_Runtime_Overrides/README.md")
        return project

    def test_source_archive_preserves_runnable_source_and_original_packs(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            project = self._fixture_project(Path(temporary))
            archive_path = Path(temporary) / "source.zip"
            package_release.write_source_archive(project, archive_path, "0.6.8")
            with zipfile.ZipFile(archive_path) as archive:
                package_release.assert_source_archive(archive, project)
                names = set(archive.namelist())
            self.assertIn("Doodle_Rumble/game/project.godot", names)
            self.assertIn("Doodle_Rumble/source_art/Blue_Transparent_Asset_Pack/production.png", names)

    def test_source_archive_preserves_authored_runtime_art_corrections(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            project = self._fixture_project(Path(temporary))
            archive_path = Path(temporary) / "source.zip"
            package_release.write_source_archive(project, archive_path, "0.6.10")
            with zipfile.ZipFile(archive_path) as archive:
                package_release.assert_source_archive(archive, project)
                names = set(archive.namelist())
            self.assertIn("Doodle_Rumble/source_art/Pac_Man_One_Eye_Runtime_Overrides/canonical.png", names)
            self.assertIn("Doodle_Rumble/source_art/Pac_Man_One_Eye_Runtime_Overrides/README.md", names)

    def test_source_archive_excludes_private_reference_cache_and_credentials(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            project = self._fixture_project(Path(temporary))
            for path in (
                "reference/kids_original_drawing.jpeg",
                "reference/kids_racing_drawing.heic",
                "planning/release_notes.md",
                "private/customer_notes.txt",
                "docs/Doodle_Rumble_Mac_Plan.docx",
                "docs/SUPPLIED_PLAN.txt",
                ".cache/package-state.json",
                ".agents/private-agent-notes.md",
                ".specify/local-work.md",
                "cache/old-output.txt",
                "game/export_credentials.cfg",
                "game/.env.production",
                "game/signing-key.p12",
                "game/api_token.txt",
            ):
                self._write(project, path)
            archive_path = Path(temporary) / "source.zip"
            package_release.write_source_archive(project, archive_path, "0.6.8")
            with zipfile.ZipFile(archive_path) as archive:
                package_release.assert_source_archive(archive, project)
                names = archive.namelist()
            forbidden = ("reference/", "planning/", "private/", "doodle_rumble_mac_plan.docx", "supplied_plan.txt", ".cache/", ".agents/", ".specify/", "cache/", "credentials", ".env", ".p12", "token")
            self.assertFalse(any(any(fragment in name.casefold() for fragment in forbidden) for name in names))

    def test_mac_archive_rejects_appledouble_metadata(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            archive_path = Path(temporary) / "mac.zip"
            with zipfile.ZipFile(archive_path, "w") as archive:
                archive.writestr("Doodle Rumble.app/Contents/MacOS/Doodle Rumble", "app")
                archive.writestr("__MACOSX/._Doodle Rumble.app", "metadata")
            with zipfile.ZipFile(archive_path) as archive:
                with self.assertRaisesRegex(AssertionError, "AppleDouble"):
                    package_release.assert_mac_archive(archive)

    def test_source_archive_does_not_follow_symlinks(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            project = self._fixture_project(root)
            external = root / "private-outside-project.txt"
            external.write_text("must not be packaged", encoding="utf-8")
            (project / "game" / "linked-private.txt").symlink_to(external)
            archive_path = root / "source.zip"
            package_release.write_source_archive(project, archive_path, "0.6.9")
            with zipfile.ZipFile(archive_path) as archive:
                self.assertNotIn("Doodle_Rumble/game/linked-private.txt", archive.namelist())

    def test_sha256_file_streams_large_files(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            file = Path(temporary) / "archive.zip"
            contents = b"doodle-rumble" * 100_000
            file.write_bytes(contents)
            self.assertEqual(package_release.sha256_file(file), hashlib.sha256(contents).hexdigest())


if __name__ == "__main__":
    unittest.main()
