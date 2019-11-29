using Documenter, ChessProject

makedocs(sitename="ChessProject", modules=[ChessProject], format=Documenter.HTML(assets=String[]),
    pages=["Home" => "index.md"], repo="https://github.com/J-Revell/ChessProject/blob/{commit}{path}#L{line}",
    authors="Jeremy Revell",
)
