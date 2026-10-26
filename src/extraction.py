import re
import sys
import fitz
from collections import Counter


def masque(ligne):
    return re.sub(r"\d+", "#", ligne)

# pour les titres
HEADING = re.compile(r"^(\d+\.(?:\d+\.?)*)\s+\S")

def extract_clauses(pdf_path):
    pages = [[l.strip() for l in p.get_text().split("\n") if l.strip()] for p in fitz.open(pdf_path)]
    
    compte = Counter(m for lignes in pages for m in {masque(l) for l in lignes})
    bruit = {m for m, c in compte.items() if c >= max(3, len(pages) / 2)}

    # découpage en clauses
    clauses = [{"article": "preambule", "page_debut": 1, "page_fin": 1, "texte": ""}]
    
    for n, lignes in enumerate(pages, start=1):
        for ligne in lignes:
            if masque(ligne) in bruit:
                continue
            m = HEADING.match(ligne)
            
            # si la ligne = un titre, on crée une nouvelle clause
            if m:
                article = m.group(1).strip(".")
                clauses.append({"article": article, "page_debut": n, "page_fin": n, "texte": ligne})
            # sinon on ajoute le texte à la clause en cours
            else:
                clauses[-1]["texte"] += " " + ligne
                clauses[-1]["page_fin"] = n

    for c in clauses:
        c["texte"] = c["texte"].strip()
    return clauses

if __name__ == "__main__":
    resultat = extract_clauses(sys.argv[1])
    print(len(resultat), "clauses extraites")
    for c in resultat[:3]:
        print(c["article"], f"p.{c['page_debut']}-{c['page_fin']}", c["texte"][:80])