"""
patch لإصلاح مشكلة onnxruntime DLL في ChromaDB على Windows.
يُشغَّل مرة واحدة — يعدّل ملف chromadb مباشرة.
"""
import sys, pathlib

# إيجاد ملف onnx_mini_lm_l6_v2.py في مجلد chromadb
site_packages = pathlib.Path(sys.executable).parent.parent / "Lib" / "site-packages"
target = site_packages / "chromadb" / "utils" / "embedding_functions" / "onnx_mini_lm_l6_v2.py"

if not target.exists():
    print(f"File not found: {target}")
    sys.exit(1)

content = target.read_text(encoding="utf-8")
print("Current content around __init__:")
for i, line in enumerate(content.splitlines()[55:75], start=56):
    print(f"{i}: {line}")

# نضيف try/except حول تحميل onnxruntime
old = '''    def __init__(self):
        try:
            self.ort = importlib.import_module("onnxruntime")
        except ModuleNotFoundError:
            raise ValueError('''

new_check = '''    def __init__(self):
        try:
            self.ort = importlib.import_module("onnxruntime")
        except (ModuleNotFoundError, ImportError, Exception):
            raise ValueError('''

if old in content:
    patched = content.replace(old, new_check)
    target.write_text(patched, encoding="utf-8")
    print("✅ Patched successfully!")
else:
    print("Pattern not found, trying alternative patch...")
    # بدل ما نعدّل، نكتب فوق الملف كاملاً بنسخة آمنة
    safe_content = content.replace(
        'except ModuleNotFoundError:',
        'except (ModuleNotFoundError, ImportError, Exception):'
    )
    if safe_content != content:
        target.write_text(safe_content, encoding="utf-8")
        print("✅ Alternative patch applied!")
    else:
        print("No change needed or pattern different.")
        
print("Done.")
