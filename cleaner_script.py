import os
import time
import subprocess
import shutil

# DIRECTORIES
INPUT_DIR = "/app/data"  # Where you put PDFs
OUTPUT_DIR = "/app/data" # Where cleaned text goes

def clean_pdf(filename):
    if not filename.endswith(".pdf"):
        return
    
    filepath = os.path.join(INPUT_DIR, filename)
    print(f"[CLEANER] Found PDF: {filename}. Cleaning...")

    # We use 'pdftotext' (part of poppler-utils we installed)
    # -layout maintains physical layout
    # -enc UTF-8 ensures characters are correct
    output_text_file = os.path.join(OUTPUT_DIR, filename.replace(".pdf", ".txt"))
    
    try:
        subprocess.run(["pdftotext", "-layout", "-enc", "UTF-8", filepath, output_text_file], check=True)
        print(f"[CLEANER] Success! Created: {output_text_file}")
        
        # Optional: Rename original to indicate it's processed
        # os.rename(filepath, filepath + ".processed")
    except Exception as e:
        print(f"[CLEANER] Error processing {filename}: {e}")

def main():
    print("[CLEANER] Service Started. Watching for PDFs...")
    while True:
        # Simple loop to check for files
        if os.path.exists(INPUT_DIR):
            for file in os.listdir(INPUT_DIR):
                if file.endswith(".pdf"):
                    # Check if text file already exists to avoid re-doing it
                    txt_name = file.replace(".pdf", ".txt")
                    if not os.path.exists(os.path.join(OUTPUT_DIR, txt_name)):
                        clean_pdf(file)
        
        time.sleep(10) # Check every 10 seconds

if __name__ == "__main__":
    main()
