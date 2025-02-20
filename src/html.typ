#import "utils.typ": *

#let repr-or-str(x) = {
  if type(x) == str {
    x
  } else {
    repr(x)
  }
}

/// HTML variant.
#let zebraw-html(
  highlight-lines: (),
  header: none,
  footer: none,
  inset: none,
  background-color: none,
  highlight-color: none,
  comment-color: none,
  lang-color: none,
  comment-flag: none,
  lang: none,
  comment-font-args: none,
  lang-font-args: none,
  extend: none,
  block-width: 42em,
  line-width: 100%,
  wrap: true,
  body,
) = context {
  let args = parse-zebraw-args(
    inset,
    background-color,
    highlight-color,
    comment-color,
    lang-color,
    comment-flag,
    lang,
    comment-font-args,
    lang-font-args,
    extend,
  )
  let inset = args.inset
  let background-color = args.background-color
  let highlight-color = args.highlight-color
  let comment-color = args.comment-color
  let lang-color = args.lang-color
  let comment-flag = args.comment-flag
  let lang = args.lang
  let comment-font-args = args.comment-font-args
  let lang-font-args = args.lang-font-args
  let extend = args.extend

  let (highlight-nums, comments) = tidy-highlight-lines(highlight-lines)

  show raw.where(block: true): it => {
    let number-div-style = (
      "margin: 0",
      "width: 2.1em",
      "text-align: right",
      "vertical-align: top",
      "padding-right: 0.34em",
      "user-select: none",
      "flex-shrink: 0",
    )

    let pre-style = (
      "padding-top: " + repr-or-str(inset.top),
      "padding-bottom: " + repr-or-str(inset.bottom),
      "margin: 0",
      ..if wrap { ("white-space: pre-wrap",) },
    )

    let text-div-style = (
      "text-align: left",
      "display: flex",
      "align-items: center",
      "width: 100%",
    )

    let comment-div-style = (
      text-div-style
        + (
          "padding-top: " + repr-or-str(inset.top),
          "padding-bottom: " + repr-or-str(inset.bottom),
        )
    )


    let background-text-style = (
      "user-select: none",
      "opacity: 0",
      "color: transparent",
    )

    let build-code-line-elem(line, is-background: false) = (
      html.elem(
        "div",
        attrs: (
          style: (
            {
              let style = ()
              style += text-div-style
              if is-background {
                style += (
                  "background: " + line.fill.to-hex(),
                )
              }
              style
            }.join("; ")
          ),
        ),
        {
          html.elem(
            "pre",
            attrs: (
              style: (
                {
                  let style = ()
                  style += number-div-style
                  if is-background {
                    style += background-text-style
                  }
                  style
                }
              ).join("; "),
            ),
            [#line.number],
          )
          html.elem(
            "pre",
            attrs: (
              style: (pre-style).join("; "),
              class: "zebraw-code-line",
            ),
            {
              show text: it => context {
                let c = text.fill
                html.elem(
                  "span",
                  attrs: (
                    style: (
                      ..if is-background {
                        background-text-style
                      } else {
                        ("color: " + c.to-hex(),)
                      },
                    ).join("; "),
                  ),
                  it,
                )
              }
              line.body
            },
          )
        },
      ),
      // haven't decided how to handle comments yet
      ..if line.comment != none {
        (
          html.elem(
            "div",
            attrs: (
              style: {
                let style = ()
                style += comment-div-style
                if is-background {
                  style += background-text-style
                }
                if wrap { style += ("white-space: pre-wrap",) } else {
                  style += ("white-space: pre",)
                }
                style
              }.join("; "),
            ),
            {
              html.elem(
                "div",
                // line.comment.indent,
                attrs: (
                  style: (
                    "width: 2.1em",
                    "flex-shrink: 0",
                  ).join("; "),
                ),
                "",
              )
              html.elem(
                "p",
                attrs: (
                  style: (
                    "margin: 0",
                    "padding: 0",
                    "width: 100%",
                  ).join("; "),
                ),
                {
                  html.elem(
                    "span",
                    attrs: (
                      style: (
                        "user-select: none",
                      ).join("; "),
                    ),
                    {
                      line.comment.indent.clusters().len() * " "
                      strong(text(ligatures: true, line.comment.comment-flag))
                      " "
                    },
                  )
                  html.elem(
                    "span",
                    attrs: (
                      style: (
                        "font-size: 0.8em",
                      ).join("; "),
                    ),
                    line.comment.body,
                  )
                },
              )
            },
          ),
        )
      },
    )


    let build-cell(is-header, content, is-background: false) = html.elem(
      "div",
      attrs: (
        style: (
          ..if is-background {
            (
              "background: "
                + if content != none { comment-color.to-hex() } else {
                  curr-background-color(background-color, 0).to-hex()
                },
            )
          },
          "width: 100%",
        ).join("; "),
      ),
      html.elem(
        "div",
        attrs: (
          style: (
            "padding: " + repr-or-str(inset.right) + " " + repr-or-str(inset.left),
            ..if is-background { background-text-style } else { none },
          ).join("; "),
        ),
        text(..comment-font-args, content),
      ),
    )

    let header-cell(is-background: false) = if header != none or comments.keys().contains("header") {
      (build-cell(true, if header != none { header } else { comments.at("header") }, is-background: is-background),)
    } else if extend {
      (build-cell(true, none, is-background: is-background),)
    } else {
      ()
    }

    let footer-cell(is-background: false) = if footer != none or comments.keys().contains("footer") {
      (build-cell(false, if footer != none { footer } else { comments.at("footer") }, is-background: is-background),)
    } else if extend {
      (build-cell(false, none, is-background: is-background),)
    } else {
      ()
    }

    let lines = tidy-lines(
      it.lines,
      highlight-nums,
      comments,
      highlight-color,
      background-color,
      comment-color,
      comment-flag,
      comment-font-args,
      is-html: true,
    )

    html.elem(
      "div",
      attrs: (
        style: (
          "position: relative",
          "width: " + repr-or-str(block-width),
        ).join("; "),
        class: "zebraw-code-block",
      ),
      {
        html.elem(
          "div",
          attrs: (
            style: (
              "position: absolute",
              "top: 0",
              "right: 0",
              "padding: 0.25em",
              "background: " + lang-color.to-hex(),
              "font-size: 0.8em",
              "border-radius: " + repr-or-str(inset.right),
            ).join("; "),
            class: "zebraw-code-lang",
          ),
          {
            if lang != false {
              set text(..lang-font-args)
              if type(lang) == bool { it.lang } else { lang }
            } else { none }
          },
        )

        // Background layer with same content
        html.elem(
          "div",
          attrs: (
            style: (
              "position: absolute",
              "top: 0",
              "left: 0",
              "width: 100%",
              "height: 100%",
              "overflow: hidden",
              "z-index: -1",
              "pointer-events: none",
              "border-radius: " + repr-or-str(inset.left),
            ).join("; "),
          ),
          (
            ..{ header-cell(is-background: true) },
            lines.map(line => build-code-line-elem(line, is-background: true)),
            ..{ footer-cell(is-background: true) },
          )
            .flatten()
            .join(),
        )

        // Foreground content
        html.elem(
          "div",
          attrs: (
            style: (
              "overflow-x: auto",
              "overflow-y: hidden",
            ).join("; "),
          ),
          (
            ..{ header-cell() },
            lines.map(line => build-code-line-elem(line)),
            ..{ footer-cell() },
          )
            .flatten()
            .join(),
        )

        html.elem(
          "script",
          ```javascript
          var codeBlocks = document.querySelectorAll('.zebraw-code-block');
          codeBlocks.forEach(function (codeBlock) {
            var copyButton = codeBlock.querySelector('.zebraw-code-lang');
            copyButton.style.cursor = 'pointer';

            // 提示用户可以复制代码 “Copy code”
            copyButton.title = 'Click to copy code';

            copyButton.addEventListener('click', function () {
              var lines = codeBlock.querySelectorAll('.zebraw-code-line');
              var code = '';
              lines.forEach(function (line) {
                code += line.textContent + '\n';
              });
              var textarea = document.createElement('textarea');
              textarea.value = code;
              document.body.appendChild(textarea);
              textarea.select();
              document.execCommand('copy');
              document.body.removeChild(textarea);

              // 提示用户代码已复制 “Code copied”
              copyButton.title = 'Code copied!';
              setTimeout(function () {
                copyButton.title = 'Click to copy code';
              }, 2000);
            });
          });
          ```.text,
        )
      },
    )
  }

  body
}
