# Qquestion Extension For Quarto

Intersperse text with short questions to the reader. They can include invisible answers or hints that are collected and can be output when format = pdf. Questions are numbered for reference, and marked by a 🤔 emoji. The extension is meant for html and pdf output.

## Installing


```bash
quarto add ute/qquestion
```

This will install the extension under the `_extensions` subdirectory.
If you're using version control, you will want to check in this directory.

## Using
![image](https://github.com/ute/qquestion/assets/5145859/1df83a91-6971-488f-b4ef-874787dd90e9)

In the yaml, add
```
filters: 
    - qquestion
```

To insert a question in the text enclose text in `{??` and `??}`. To add an answer or hint to the question, separate the answer text from question by `:|:`, within the same pair of brackets.

To collect answers for use in pdf, add the LaTeX command `\collectanswers` before any question with answers. Retrieve answers including a reference number by adding the LaTeX command `\qsolutions` in your text.

Change appearance of questions and answers by hacking the files `qquestions.css` and `qquestions.tex`.

## Example

Here is the source code for a minimal example: [example.qmd](example.qmd).

## Quirks

In book projects, questions are numbered accross chapters. The way it is done now (v0.2.0) gives funny results in the previewer, but works well when rendering the whole project at once.