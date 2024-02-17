# Qquestion Extension For Quarto

Intersperse text with short questions to the reader. They can include invisible answers or hints that are collected and can be output when format = pdf. Questions are numbered for reference

## Installing


```bash
quarto add ute/qquestion
```

This will install the extension under the `_extensions` subdirectory.
If you're using version control, you will want to check in this directory.

## Using

In the yaml, add
```
filters: 
    - qquestion
```

To insert a question in the text enclose text in `{??` and `??}`. To add an answer or hint to the question, separate the answer text from question by `:|:`, within the same pair of brackets.

To collect answers for use in pdf, add the LaTeX command `\collectanswers` before any question with answers. Retrieve answers including a reference number by adding the LaTeX command `\qsolutions` in your text.

## Example

Here is the source code for a minimal example: [example.qmd](example.qmd).

