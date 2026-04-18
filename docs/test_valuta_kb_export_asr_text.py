import hashlib
import importlib.util
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("valuta-kb-export-asr-text.py")


def load_module():
    spec = importlib.util.spec_from_file_location("valuta_kb_export_asr_text", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


class ValutaKbExportAsrTextTests(unittest.TestCase):
    def test_output_path_for_media_uses_hash_and_txt_extension(self):
        module = load_module()

        media_path = Path(r"D:\repo\valutavalto-program\Felmérés\Valuta\Hang 003_sd.m4a")
        output_root = Path(r"D:\repo\valutavalto-program\docs\knowledge\generated\asr-text")

        result = module.output_path_for_media(media_path, output_root)

        self.assertEqual(result.parent, output_root)
        self.assertEqual(result.suffix, ".txt")
        self.assertIn("Hang_003_sd", result.stem)

    def test_group_media_files_collapses_duplicate_hashes(self):
        module = load_module()

        with tempfile.TemporaryDirectory() as tmp_dir:
            root = Path(tmp_dir)
            a = root / "a.m4a"
            b = root / "b.m4a"
            c = root / "c.m4a"
            a.write_bytes(b"same-audio")
            b.write_bytes(b"same-audio")
            c.write_bytes(b"other-audio")

            grouped = module.group_media_files([a, b, c])

        self.assertEqual(len(grouped), 2)
        self.assertEqual(grouped[0][0], a)
        self.assertEqual(grouped[0][1], [a, b])
        self.assertEqual(grouped[1][0], c)
        self.assertEqual(grouped[1][1], [c])

    def test_sha256_for_path_matches_hashlib(self):
        module = load_module()

        with tempfile.TemporaryDirectory() as tmp_dir:
            sample = Path(tmp_dir) / "sample.m4a"
            payload = b"audio-bytes"
            sample.write_bytes(payload)

            result = module.sha256_for_path(sample)

        self.assertEqual(result, hashlib.sha256(payload).hexdigest())


if __name__ == "__main__":
    unittest.main()
