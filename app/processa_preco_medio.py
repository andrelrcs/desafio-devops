import csv
import json
import argparse
from collections import defaultdict
from typing import Dict, Tuple


def calcular_medias_por_ano_e_marca(caminho_csv: str) -> Dict[str, Dict[str, float]]:
    somas_e_contagens: Dict[Tuple[int, str], Tuple[float, int]] = {}

    with open(caminho_csv, "r", encoding="utf-8", newline="") as f:
        leitor = csv.reader(f)
        cabecalho = next(leitor, None)

        if cabecalho is None:
            raise ValueError("CSV sem cabeçalho ou vazio.")

        # Detecta índices das colunas relevantes.
        # O arquivo possui uma primeira coluna vazia (índice), então tratamos por nome.
        nome_para_indice: Dict[str, int] = {nome: i for i, nome in enumerate(cabecalho)}

        # Nomes esperados conforme arquivo: '', 'codigoFipe', 'marca', 'modelo', 'anoModelo', 'mesReferencia', 'anoReferencia', 'valor'
        col_ano = nome_para_indice.get("anoModelo")
        col_marca = nome_para_indice.get("marca")
        col_valor = nome_para_indice.get("valor")

        if col_ano is None or col_marca is None or col_valor is None:
            raise ValueError(
                "Cabeçalho inesperado. Esperado conter colunas 'anoModelo', 'marca' e 'valor'."
            )

        for linha in leitor:
            try:
                ano_str = linha[col_ano].strip()
                marca = linha[col_marca].strip()
                valor_str = linha[col_valor].strip()

                if not ano_str or not marca or not valor_str:
                    continue

                ano = int(ano_str)

                # Valor no arquivo já está com ponto decimal (ex.: 13041.0)
                # Para robustez, removemos espaços e trocamos vírgula por ponto, e removemos separadores não numéricos.
                valor_normalizado = (
                    valor_str.replace(" ", "").replace("\u00A0", "").replace(",", ".")
                )
                valor = float(valor_normalizado)

                chave = (ano, marca)
                if chave in somas_e_contagens:
                    soma, cont = somas_e_contagens[chave]
                    somas_e_contagens[chave] = (soma + valor, cont + 1)
                else:
                    somas_e_contagens[chave] = (valor, 1)
            except (IndexError, ValueError):
                # Ignora linhas malformadas
                continue

    # Constrói estrutura { anoModelo: { marca: preco_medio } }
    resultado: Dict[str, Dict[str, float]] = defaultdict(dict)

    for (ano, marca), (soma, cont) in somas_e_contagens.items():
        media = soma / cont if cont else 0.0
        # Armazena com duas casas decimais
        resultado[str(ano)][marca] = round(media, 2)

    # Ordena por ano e por marca para consistência
    resultado_ordenado: Dict[str, Dict[str, float]] = {}
    for ano in sorted(resultado.keys(), key=lambda x: int(x)):
        marcas = resultado[ano]
        marcas_ordenadas = {m: marcas[m] for m in sorted(marcas.keys())}
        resultado_ordenado[ano] = marcas_ordenadas

    return resultado_ordenado


def main():
    parser = argparse.ArgumentParser(
        description=(
            "Processa um CSV da tabela FIPE histórica e gera um JSON com o preço "
            "médio por anoModelo e por marca."
        )
    )
    parser.add_argument(
        "--input",
        "-i",
        default="tabela-fipe-historico-precos.csv",
        help="Caminho do arquivo CSV de entrada (padrão: tabela-fipe-historico-precos.csv)",
    )
    parser.add_argument(
        "--output",
        "-o",
        default="preco_medio_por_ano_marca.json",
        help="Caminho do arquivo JSON de saída (padrão: preco_medio_por_ano_marca.json)",
    )

    args = parser.parse_args()

    medias = calcular_medias_por_ano_e_marca(args.input)

    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(medias, f, ensure_ascii=False, indent=2)

    print(f"Arquivo JSON gerado em: {args.output}")


if __name__ == "__main__":
    main()