function CodeBlock(cb)
    if cb.classes[1] == "mermaid" then
        return pandoc.RawBlock(
            "html",
            '<pre class="mermaid">\n' ..
            cb.text ..
            '\n</pre>'
        )
    end
end
