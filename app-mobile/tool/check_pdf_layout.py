#!/usr/bin/env python3
"""Page-level regression checks for the fictional PDF fixture.

Requires Poppler's pdftotext. This intentionally does not read or store
real case documents, personal data, or operational photographs.
"""

from pathlib import Path
import re
import subprocess
import sys

SECTIONS = (
    "1. Informações Gerais",
    "2. Descrição da Ocorrência",
    "3. Desenvolvimento do emprego da equipe",
    "4. Recursos Utilizados",
    "5. Conclusão",
    "6. Anexo",
)

# Each section's first field must share the page with its heading.
GROUP_FIRST_FIELDS = {
    "INFORMAÇÕES GERAIS": "Data do fato",
    "MOTIVAÇÃO / HISTÓRIA / DESTINO": "Histórico / motivação",
    "MEIO DE TRANSPORTE": "A pé",
    "VISTO PELA ÚLTIMA VEZ": "Quando",
    "DESCRIÇÃO FÍSICA": "Idade",
    "VESTIMENTAS / ACESSÓRIOS": "Itens",
    "MATERIAIS / EQUIPAMENTOS / SUPRIMENTOS": "Materiais pessoais",
    "SAÚDE E COMPORTAMENTO": "Condição geral",
    "EXPERIÊNCIA E RESISTÊNCIA FÍSICA": "Experiência em caminhada",
    "PROCEDIMENTOS REALIZADOS ATÉ O MOMENTO": "Ações empreendidas",
}

# These strings belong to the synthetic fixture produced in report_pdf_test.dart.
ANNEXES = (
    ("Anexo 02 -", "Legenda fictícia da primeira fotografia.", "imagem-ficticia-01.png"),
    ("Anexo 03 -", "Legenda fictícia mais longa", "imagem-ficticia-02.png"),
)


def extract_pages(file_path: Path) -> list[str]:
    result = subprocess.run(
        ["pdftotext", "-layout", "-enc", "UTF-8", str(file_path), "-"],
        check=True,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    return [page for page in result.stdout.split("\f") if page.strip()]


def normalized(value: str) -> str:
    return " ".join(value.split())


def line_is(page: str, title: str) -> bool:
    return any(normalized(line) == title for line in page.splitlines())


def main(file_path: Path) -> int:
    if not file_path.is_file():
        print(f"PDF fixture not found: {file_path}", file=sys.stderr)
        return 2

    pages = extract_pages(file_path)
    errors: list[str] = []
    if len(pages) < 5:
        errors.append(f"Expected multipage report; found {len(pages)} pages")

    if len(pages) > 1:
        contents = [normalized(line) for line in pages[1].splitlines()]
        if "Sumário" not in contents:
            errors.append("Page 2 has no Sumário title")
        for title in SECTIONS:
            matching_rows = [line for line in contents if line.startswith(title)]
            if len(matching_rows) != 1:
                errors.append(f"Contents entry missing/duplicated: {title}")
                continue
            entry = re.fullmatch(re.escape(title) + r"\s+(\d+)", matching_rows[0])
            if entry is None:
                errors.append(f"Contents entry has no page number: {title}")
                continue
            matches = [index for index, page in enumerate(pages) if index >= 2 and line_is(page, title)]
            if len(matches) != 1:
                errors.append(f"Body section missing/duplicated: {title}")
                continue
            # The cover is unnumbered; page index 2 is physical page 3,
            # and its printed number is 2.
            expected_page_label = matches[0]
            if int(entry.group(1)) != expected_page_label:
                errors.append(f"Wrong page number for {title}: {entry.group(1)} != {expected_page_label}")

    for group, first_field in GROUP_FIRST_FIELDS.items():
        group_pages = []
        for number, page in enumerate(pages[2:], start=3):
            lines = [normalized(line) for line in page.splitlines()]
            if group not in lines:
                continue
            group_pages.append(number)
            start = lines.index(group) + 1
            if not any(first_field in line for line in lines[start:]):
                errors.append(f"Orphan group title on physical page {number}: {group}")
        if len(group_pages) != 1:
            errors.append(f"Triage title missing/duplicated: {group} ({group_pages})")

    for heading, caption, filename in ANNEXES:
        annex_pages = [
            (index + 1, page) for index, page in enumerate(pages) if heading in page
        ]
        if len(annex_pages) != 1:
            errors.append(f"Annex heading missing/duplicated: {heading}")
            continue
        number, page = annex_pages[0]
        if caption not in normalized(page):
            errors.append(f"Caption is missing/separated from {heading} (physical page {number})")
        if filename not in page:
            errors.append(f"Filename is missing/separated from {heading} (physical page {number})")

    if errors:
        for issue in errors:
            print(f"FAIL PDF layout: {issue}", file=sys.stderr)
        return 1

    print(
        f"PASS PDF layout: {len(pages)} pages, six indexed sections, "
        f"{len(GROUP_FIRST_FIELDS)} grouped headings, {len(ANNEXES)} complete photo annexes"
    )
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 tool/check_pdf_layout.py <synthetic-report.pdf>", file=sys.stderr)
        raise SystemExit(2)
    raise SystemExit(main(Path(sys.argv[1])))
