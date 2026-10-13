<!--
  THE SOURCE OF TRUTH for the talk's slides. Edit this file, then run:

      make slides   rebuild docs/slides.html (the web deck; needs only Python)
      make pptx     rebuild docs/slides.html AND docs/slides.pptx (needs Node)

  docs/slides.html and docs/slides.pptx are generated. Never edit them by hand:
  the next build overwrites the change. If you fix something in PowerPoint, make
  the same fix here.

  Each slide starts with `## <n>. <title>` followed by key: value lines:
    section:  grouping name, shown bottom-left and in the progress bar
              (PowerPoint: the section groups in the slide sorter)
    eyebrow:  small label above the headline (may contain <span class="chip">)
    layout:   omit for a normal slide; `title` for the opening slide;
              `bare` for a slide whose heading should not be printed
  Then the slide body. Plain markdown bullets become the big bullet list;
  anything that starts with `<` is passed through as HTML. A `### notes` section
  at the end becomes the speaker notes (the N key; PowerPoint's notes pane).

  CODE BLOCKS: put three backticks on a line of their own before the code and
  after it. The block becomes a code box and is escaped for you, so `<`, `>` and
  `&` can be written as they are (`<<-SHELL` is fine). A line in a fence that
  starts with `## ` or says `### notes` is not mistaken for a heading. This works
  in the slide body and in the notes. It does not work inside a raw HTML block
  such as a div.cols; there, write a `<pre>` and escape `<` as `&lt;` yourself.
  A block shrinks to fit about one screen (down to 11px), so keep the other text
  on that slide short. For a terminal-style block (dark, with dimmed prompts) use
  div.term instead.

  HTML blocks the PowerPoint export understands (anything else is reported as an
  ERROR by `make pptx`, and the build exits non-zero):
    p.lede  p.big  p.small  p.quote  h3          text
    ul.points  ol.steps                          bullet and numbered lists
    pre  div.term                                code and terminal boxes
    table                                        native table
    dl.facts  div.ledger  div.plan-summary       fact rows and terraform-plan ledgers
    div.examples  div.callout  div.legend        chip rows, callouts, chart legend
    div.cols  div.cols-3  div.code-grid
    div.apptype  div.fill                        layout containers
    figure > svg  (rect, text, path, line)       diagrams, redrawn as native shapes
  `make pptx` also warns when a slide's content runs off the bottom of the page.
-->

<!-- Standalone teaching repository: playful-programming-terraform-demo.
  This deck has 47 slides and closes with the repository URL.
  Only the improved main deck is included; edit it here and run make pptx.
  See SLIDE_DECKS.md for the delivery budget. -->

# From Git commits to Terraform

## 1. From Git commits to Terraform
section: Opening
eyebrow: <span class="chip">Playful Programming</span> Bike Dog Brewing
layout: title

<div class="title-meta">
  <p class="lede">From a git push to four kinds of app, provisioned locally</p>
  <div class="ribbon" aria-hidden="true"><i></i><i></i><i></i><i></i><i></i></div>
</div>

### notes

<p>Welcome. The whole talk runs live against a local AWS emulator. Nobody in this room needs an account to follow along; the repo link and QR code are on the next slide.</p>
<p>The colored bar is the key for every slide: teal is CDN, indigo is network, plum is compute, ochre is data, brick is access and IAM.</p>

## 2. Get the slides and follow along
section: Opening
eyebrow: Optional · you can just watch · no AWS account needed

<p class="big"><a href="https://github.com/raysapida/terraform_demo" style="color:var(--edge);text-underline-offset:0.15em">https://github.com/raysapida/terraform_demo</a></p>
<div class="cols">
  <figure>
    <svg viewBox="0 0 520 310" role="img" aria-label="QR code linking to https://github.com/raysapida/terraform_demo">
    <rect x="110" y="0" width="301" height="301" fill="#ffffff"/>
    <rect x="145" y="35" width="49" height="7" fill="#000000"/>
    <rect x="208" y="35" width="28" height="7" fill="#000000"/>
    <rect x="243" y="35" width="7" height="7" fill="#000000"/>
    <rect x="257" y="35" width="7" height="7" fill="#000000"/>
    <rect x="278" y="35" width="21" height="7" fill="#000000"/>
    <rect x="306" y="35" width="7" height="7" fill="#000000"/>
    <rect x="327" y="35" width="49" height="7" fill="#000000"/>
    <rect x="145" y="42" width="7" height="7" fill="#000000"/>
    <rect x="187" y="42" width="7" height="7" fill="#000000"/>
    <rect x="250" y="42" width="14" height="7" fill="#000000"/>
    <rect x="271" y="42" width="7" height="7" fill="#000000"/>
    <rect x="285" y="42" width="14" height="7" fill="#000000"/>
    <rect x="327" y="42" width="7" height="7" fill="#000000"/>
    <rect x="369" y="42" width="7" height="7" fill="#000000"/>
    <rect x="145" y="49" width="7" height="7" fill="#000000"/>
    <rect x="159" y="49" width="21" height="7" fill="#000000"/>
    <rect x="187" y="49" width="7" height="7" fill="#000000"/>
    <rect x="201" y="49" width="14" height="7" fill="#000000"/>
    <rect x="243" y="49" width="7" height="7" fill="#000000"/>
    <rect x="257" y="49" width="7" height="7" fill="#000000"/>
    <rect x="292" y="49" width="14" height="7" fill="#000000"/>
    <rect x="327" y="49" width="7" height="7" fill="#000000"/>
    <rect x="341" y="49" width="21" height="7" fill="#000000"/>
    <rect x="369" y="49" width="7" height="7" fill="#000000"/>
    <rect x="145" y="56" width="7" height="7" fill="#000000"/>
    <rect x="159" y="56" width="21" height="7" fill="#000000"/>
    <rect x="187" y="56" width="7" height="7" fill="#000000"/>
    <rect x="201" y="56" width="7" height="7" fill="#000000"/>
    <rect x="222" y="56" width="7" height="7" fill="#000000"/>
    <rect x="271" y="56" width="7" height="7" fill="#000000"/>
    <rect x="292" y="56" width="7" height="7" fill="#000000"/>
    <rect x="313" y="56" width="7" height="7" fill="#000000"/>
    <rect x="327" y="56" width="7" height="7" fill="#000000"/>
    <rect x="341" y="56" width="21" height="7" fill="#000000"/>
    <rect x="369" y="56" width="7" height="7" fill="#000000"/>
    <rect x="145" y="63" width="7" height="7" fill="#000000"/>
    <rect x="159" y="63" width="21" height="7" fill="#000000"/>
    <rect x="187" y="63" width="7" height="7" fill="#000000"/>
    <rect x="201" y="63" width="7" height="7" fill="#000000"/>
    <rect x="215" y="63" width="21" height="7" fill="#000000"/>
    <rect x="243" y="63" width="28" height="7" fill="#000000"/>
    <rect x="285" y="63" width="21" height="7" fill="#000000"/>
    <rect x="327" y="63" width="7" height="7" fill="#000000"/>
    <rect x="341" y="63" width="21" height="7" fill="#000000"/>
    <rect x="369" y="63" width="7" height="7" fill="#000000"/>
    <rect x="145" y="70" width="7" height="7" fill="#000000"/>
    <rect x="187" y="70" width="7" height="7" fill="#000000"/>
    <rect x="201" y="70" width="7" height="7" fill="#000000"/>
    <rect x="243" y="70" width="7" height="7" fill="#000000"/>
    <rect x="271" y="70" width="14" height="7" fill="#000000"/>
    <rect x="306" y="70" width="14" height="7" fill="#000000"/>
    <rect x="327" y="70" width="7" height="7" fill="#000000"/>
    <rect x="369" y="70" width="7" height="7" fill="#000000"/>
    <rect x="145" y="77" width="49" height="7" fill="#000000"/>
    <rect x="201" y="77" width="7" height="7" fill="#000000"/>
    <rect x="215" y="77" width="7" height="7" fill="#000000"/>
    <rect x="229" y="77" width="7" height="7" fill="#000000"/>
    <rect x="243" y="77" width="7" height="7" fill="#000000"/>
    <rect x="257" y="77" width="7" height="7" fill="#000000"/>
    <rect x="271" y="77" width="7" height="7" fill="#000000"/>
    <rect x="285" y="77" width="7" height="7" fill="#000000"/>
    <rect x="299" y="77" width="7" height="7" fill="#000000"/>
    <rect x="313" y="77" width="7" height="7" fill="#000000"/>
    <rect x="327" y="77" width="49" height="7" fill="#000000"/>
    <rect x="201" y="84" width="7" height="7" fill="#000000"/>
    <rect x="215" y="84" width="14" height="7" fill="#000000"/>
    <rect x="257" y="84" width="7" height="7" fill="#000000"/>
    <rect x="278" y="84" width="21" height="7" fill="#000000"/>
    <rect x="306" y="84" width="7" height="7" fill="#000000"/>
    <rect x="145" y="91" width="7" height="7" fill="#000000"/>
    <rect x="159" y="91" width="35" height="7" fill="#000000"/>
    <rect x="236" y="91" width="14" height="7" fill="#000000"/>
    <rect x="264" y="91" width="7" height="7" fill="#000000"/>
    <rect x="278" y="91" width="7" height="7" fill="#000000"/>
    <rect x="306" y="91" width="7" height="7" fill="#000000"/>
    <rect x="327" y="91" width="35" height="7" fill="#000000"/>
    <rect x="159" y="98" width="14" height="7" fill="#000000"/>
    <rect x="180" y="98" width="7" height="7" fill="#000000"/>
    <rect x="208" y="98" width="7" height="7" fill="#000000"/>
    <rect x="236" y="98" width="7" height="7" fill="#000000"/>
    <rect x="264" y="98" width="7" height="7" fill="#000000"/>
    <rect x="278" y="98" width="14" height="7" fill="#000000"/>
    <rect x="306" y="98" width="7" height="7" fill="#000000"/>
    <rect x="327" y="98" width="14" height="7" fill="#000000"/>
    <rect x="348" y="98" width="14" height="7" fill="#000000"/>
    <rect x="369" y="98" width="7" height="7" fill="#000000"/>
    <rect x="180" y="105" width="91" height="7" fill="#000000"/>
    <rect x="299" y="105" width="7" height="7" fill="#000000"/>
    <rect x="313" y="105" width="21" height="7" fill="#000000"/>
    <rect x="341" y="105" width="7" height="7" fill="#000000"/>
    <rect x="355" y="105" width="14" height="7" fill="#000000"/>
    <rect x="152" y="112" width="14" height="7" fill="#000000"/>
    <rect x="173" y="112" width="7" height="7" fill="#000000"/>
    <rect x="194" y="112" width="14" height="7" fill="#000000"/>
    <rect x="215" y="112" width="7" height="7" fill="#000000"/>
    <rect x="229" y="112" width="14" height="7" fill="#000000"/>
    <rect x="250" y="112" width="7" height="7" fill="#000000"/>
    <rect x="264" y="112" width="21" height="7" fill="#000000"/>
    <rect x="313" y="112" width="21" height="7" fill="#000000"/>
    <rect x="341" y="112" width="21" height="7" fill="#000000"/>
    <rect x="369" y="112" width="7" height="7" fill="#000000"/>
    <rect x="145" y="119" width="7" height="7" fill="#000000"/>
    <rect x="187" y="119" width="21" height="7" fill="#000000"/>
    <rect x="222" y="119" width="7" height="7" fill="#000000"/>
    <rect x="243" y="119" width="21" height="7" fill="#000000"/>
    <rect x="285" y="119" width="42" height="7" fill="#000000"/>
    <rect x="348" y="119" width="7" height="7" fill="#000000"/>
    <rect x="145" y="126" width="7" height="7" fill="#000000"/>
    <rect x="201" y="126" width="14" height="7" fill="#000000"/>
    <rect x="222" y="126" width="7" height="7" fill="#000000"/>
    <rect x="236" y="126" width="7" height="7" fill="#000000"/>
    <rect x="250" y="126" width="7" height="7" fill="#000000"/>
    <rect x="271" y="126" width="7" height="7" fill="#000000"/>
    <rect x="313" y="126" width="7" height="7" fill="#000000"/>
    <rect x="327" y="126" width="7" height="7" fill="#000000"/>
    <rect x="355" y="126" width="21" height="7" fill="#000000"/>
    <rect x="152" y="133" width="7" height="7" fill="#000000"/>
    <rect x="166" y="133" width="35" height="7" fill="#000000"/>
    <rect x="215" y="133" width="14" height="7" fill="#000000"/>
    <rect x="236" y="133" width="42" height="7" fill="#000000"/>
    <rect x="285" y="133" width="7" height="7" fill="#000000"/>
    <rect x="299" y="133" width="7" height="7" fill="#000000"/>
    <rect x="320" y="133" width="14" height="7" fill="#000000"/>
    <rect x="348" y="133" width="21" height="7" fill="#000000"/>
    <rect x="145" y="140" width="21" height="7" fill="#000000"/>
    <rect x="173" y="140" width="7" height="7" fill="#000000"/>
    <rect x="201" y="140" width="14" height="7" fill="#000000"/>
    <rect x="250" y="140" width="7" height="7" fill="#000000"/>
    <rect x="292" y="140" width="7" height="7" fill="#000000"/>
    <rect x="306" y="140" width="7" height="7" fill="#000000"/>
    <rect x="320" y="140" width="14" height="7" fill="#000000"/>
    <rect x="341" y="140" width="21" height="7" fill="#000000"/>
    <rect x="145" y="147" width="21" height="7" fill="#000000"/>
    <rect x="173" y="147" width="7" height="7" fill="#000000"/>
    <rect x="187" y="147" width="7" height="7" fill="#000000"/>
    <rect x="201" y="147" width="7" height="7" fill="#000000"/>
    <rect x="222" y="147" width="21" height="7" fill="#000000"/>
    <rect x="250" y="147" width="7" height="7" fill="#000000"/>
    <rect x="264" y="147" width="7" height="7" fill="#000000"/>
    <rect x="285" y="147" width="7" height="7" fill="#000000"/>
    <rect x="299" y="147" width="28" height="7" fill="#000000"/>
    <rect x="334" y="147" width="14" height="7" fill="#000000"/>
    <rect x="369" y="147" width="7" height="7" fill="#000000"/>
    <rect x="145" y="154" width="28" height="7" fill="#000000"/>
    <rect x="180" y="154" width="7" height="7" fill="#000000"/>
    <rect x="201" y="154" width="14" height="7" fill="#000000"/>
    <rect x="229" y="154" width="7" height="7" fill="#000000"/>
    <rect x="257" y="154" width="7" height="7" fill="#000000"/>
    <rect x="271" y="154" width="28" height="7" fill="#000000"/>
    <rect x="306" y="154" width="7" height="7" fill="#000000"/>
    <rect x="327" y="154" width="14" height="7" fill="#000000"/>
    <rect x="348" y="154" width="28" height="7" fill="#000000"/>
    <rect x="152" y="161" width="42" height="7" fill="#000000"/>
    <rect x="201" y="161" width="14" height="7" fill="#000000"/>
    <rect x="222" y="161" width="7" height="7" fill="#000000"/>
    <rect x="236" y="161" width="7" height="7" fill="#000000"/>
    <rect x="250" y="161" width="7" height="7" fill="#000000"/>
    <rect x="271" y="161" width="7" height="7" fill="#000000"/>
    <rect x="285" y="161" width="14" height="7" fill="#000000"/>
    <rect x="313" y="161" width="14" height="7" fill="#000000"/>
    <rect x="334" y="161" width="14" height="7" fill="#000000"/>
    <rect x="355" y="161" width="14" height="7" fill="#000000"/>
    <rect x="145" y="168" width="7" height="7" fill="#000000"/>
    <rect x="159" y="168" width="21" height="7" fill="#000000"/>
    <rect x="194" y="168" width="28" height="7" fill="#000000"/>
    <rect x="250" y="168" width="14" height="7" fill="#000000"/>
    <rect x="278" y="168" width="28" height="7" fill="#000000"/>
    <rect x="334" y="168" width="28" height="7" fill="#000000"/>
    <rect x="369" y="168" width="7" height="7" fill="#000000"/>
    <rect x="145" y="175" width="14" height="7" fill="#000000"/>
    <rect x="187" y="175" width="7" height="7" fill="#000000"/>
    <rect x="201" y="175" width="14" height="7" fill="#000000"/>
    <rect x="222" y="175" width="7" height="7" fill="#000000"/>
    <rect x="236" y="175" width="21" height="7" fill="#000000"/>
    <rect x="271" y="175" width="14" height="7" fill="#000000"/>
    <rect x="292" y="175" width="7" height="7" fill="#000000"/>
    <rect x="313" y="175" width="14" height="7" fill="#000000"/>
    <rect x="334" y="175" width="21" height="7" fill="#000000"/>
    <rect x="145" y="182" width="14" height="7" fill="#000000"/>
    <rect x="173" y="182" width="7" height="7" fill="#000000"/>
    <rect x="222" y="182" width="7" height="7" fill="#000000"/>
    <rect x="250" y="182" width="14" height="7" fill="#000000"/>
    <rect x="285" y="182" width="28" height="7" fill="#000000"/>
    <rect x="327" y="182" width="7" height="7" fill="#000000"/>
    <rect x="348" y="182" width="14" height="7" fill="#000000"/>
    <rect x="369" y="182" width="7" height="7" fill="#000000"/>
    <rect x="145" y="189" width="7" height="7" fill="#000000"/>
    <rect x="159" y="189" width="21" height="7" fill="#000000"/>
    <rect x="187" y="189" width="14" height="7" fill="#000000"/>
    <rect x="208" y="189" width="28" height="7" fill="#000000"/>
    <rect x="243" y="189" width="7" height="7" fill="#000000"/>
    <rect x="271" y="189" width="14" height="7" fill="#000000"/>
    <rect x="320" y="189" width="7" height="7" fill="#000000"/>
    <rect x="334" y="189" width="14" height="7" fill="#000000"/>
    <rect x="362" y="189" width="7" height="7" fill="#000000"/>
    <rect x="145" y="196" width="7" height="7" fill="#000000"/>
    <rect x="180" y="196" width="7" height="7" fill="#000000"/>
    <rect x="215" y="196" width="14" height="7" fill="#000000"/>
    <rect x="236" y="196" width="14" height="7" fill="#000000"/>
    <rect x="257" y="196" width="7" height="7" fill="#000000"/>
    <rect x="278" y="196" width="28" height="7" fill="#000000"/>
    <rect x="320" y="196" width="21" height="7" fill="#000000"/>
    <rect x="348" y="196" width="28" height="7" fill="#000000"/>
    <rect x="145" y="203" width="7" height="7" fill="#000000"/>
    <rect x="159" y="203" width="7" height="7" fill="#000000"/>
    <rect x="173" y="203" width="21" height="7" fill="#000000"/>
    <rect x="208" y="203" width="28" height="7" fill="#000000"/>
    <rect x="243" y="203" width="7" height="7" fill="#000000"/>
    <rect x="264" y="203" width="7" height="7" fill="#000000"/>
    <rect x="278" y="203" width="7" height="7" fill="#000000"/>
    <rect x="299" y="203" width="49" height="7" fill="#000000"/>
    <rect x="369" y="203" width="7" height="7" fill="#000000"/>
    <rect x="201" y="210" width="42" height="7" fill="#000000"/>
    <rect x="257" y="210" width="14" height="7" fill="#000000"/>
    <rect x="278" y="210" width="7" height="7" fill="#000000"/>
    <rect x="306" y="210" width="14" height="7" fill="#000000"/>
    <rect x="341" y="210" width="7" height="7" fill="#000000"/>
    <rect x="355" y="210" width="21" height="7" fill="#000000"/>
    <rect x="145" y="217" width="49" height="7" fill="#000000"/>
    <rect x="236" y="217" width="35" height="7" fill="#000000"/>
    <rect x="285" y="217" width="7" height="7" fill="#000000"/>
    <rect x="299" y="217" width="21" height="7" fill="#000000"/>
    <rect x="327" y="217" width="7" height="7" fill="#000000"/>
    <rect x="341" y="217" width="7" height="7" fill="#000000"/>
    <rect x="355" y="217" width="14" height="7" fill="#000000"/>
    <rect x="145" y="224" width="7" height="7" fill="#000000"/>
    <rect x="187" y="224" width="7" height="7" fill="#000000"/>
    <rect x="201" y="224" width="7" height="7" fill="#000000"/>
    <rect x="243" y="224" width="14" height="7" fill="#000000"/>
    <rect x="264" y="224" width="14" height="7" fill="#000000"/>
    <rect x="285" y="224" width="7" height="7" fill="#000000"/>
    <rect x="306" y="224" width="14" height="7" fill="#000000"/>
    <rect x="341" y="224" width="28" height="7" fill="#000000"/>
    <rect x="145" y="231" width="7" height="7" fill="#000000"/>
    <rect x="159" y="231" width="21" height="7" fill="#000000"/>
    <rect x="187" y="231" width="7" height="7" fill="#000000"/>
    <rect x="201" y="231" width="14" height="7" fill="#000000"/>
    <rect x="222" y="231" width="7" height="7" fill="#000000"/>
    <rect x="243" y="231" width="7" height="7" fill="#000000"/>
    <rect x="257" y="231" width="7" height="7" fill="#000000"/>
    <rect x="278" y="231" width="28" height="7" fill="#000000"/>
    <rect x="313" y="231" width="42" height="7" fill="#000000"/>
    <rect x="362" y="231" width="7" height="7" fill="#000000"/>
    <rect x="145" y="238" width="7" height="7" fill="#000000"/>
    <rect x="159" y="238" width="21" height="7" fill="#000000"/>
    <rect x="187" y="238" width="7" height="7" fill="#000000"/>
    <rect x="201" y="238" width="42" height="7" fill="#000000"/>
    <rect x="250" y="238" width="7" height="7" fill="#000000"/>
    <rect x="271" y="238" width="7" height="7" fill="#000000"/>
    <rect x="306" y="238" width="21" height="7" fill="#000000"/>
    <rect x="341" y="238" width="14" height="7" fill="#000000"/>
    <rect x="369" y="238" width="7" height="7" fill="#000000"/>
    <rect x="145" y="245" width="7" height="7" fill="#000000"/>
    <rect x="159" y="245" width="21" height="7" fill="#000000"/>
    <rect x="187" y="245" width="7" height="7" fill="#000000"/>
    <rect x="201" y="245" width="7" height="7" fill="#000000"/>
    <rect x="215" y="245" width="7" height="7" fill="#000000"/>
    <rect x="236" y="245" width="7" height="7" fill="#000000"/>
    <rect x="250" y="245" width="14" height="7" fill="#000000"/>
    <rect x="271" y="245" width="7" height="7" fill="#000000"/>
    <rect x="285" y="245" width="7" height="7" fill="#000000"/>
    <rect x="299" y="245" width="7" height="7" fill="#000000"/>
    <rect x="327" y="245" width="14" height="7" fill="#000000"/>
    <rect x="348" y="245" width="7" height="7" fill="#000000"/>
    <rect x="145" y="252" width="7" height="7" fill="#000000"/>
    <rect x="187" y="252" width="7" height="7" fill="#000000"/>
    <rect x="208" y="252" width="28" height="7" fill="#000000"/>
    <rect x="250" y="252" width="7" height="7" fill="#000000"/>
    <rect x="271" y="252" width="7" height="7" fill="#000000"/>
    <rect x="292" y="252" width="14" height="7" fill="#000000"/>
    <rect x="320" y="252" width="7" height="7" fill="#000000"/>
    <rect x="341" y="252" width="21" height="7" fill="#000000"/>
    <rect x="145" y="259" width="49" height="7" fill="#000000"/>
    <rect x="201" y="259" width="7" height="7" fill="#000000"/>
    <rect x="222" y="259" width="7" height="7" fill="#000000"/>
    <rect x="243" y="259" width="14" height="7" fill="#000000"/>
    <rect x="264" y="259" width="7" height="7" fill="#000000"/>
    <rect x="299" y="259" width="28" height="7" fill="#000000"/>
    <rect x="334" y="259" width="7" height="7" fill="#000000"/>
    <rect x="348" y="259" width="7" height="7" fill="#000000"/>
    <rect x="362" y="259" width="7" height="7" fill="#000000"/>
    </svg>
    <figcaption>Scan for the slides and demo code</figcaption>
  </figure>
  <div>
    <dl class="facts" style="gap:16px">
      <div class="fact"><dt>Install</dt><dd>Docker (running, Compose v2) · Terraform ≥ 1.5 · AWS CLI</dd></div>
      <div class="fact"><dt>Later stacks</dt><dd>Stack 3: Ruby 4.0.5 + Bundler, or just watch.</dd></div>
    </dl>
    <div class="term" style="margin-top:18px"><span class="p">$</span> git clone https://github.com/raysapida/terraform_demo
<span class="p">$</span> cd terraform_demo
<span class="p">$</span> make doctor
<span class="p">$</span> make prepare</div>
    <p class="small" style="margin-top:18px">Leave <code>make prepare</code> running while we go through deployment. It starts Floci and downloads the demo images.</p>
  </div>
</div>

### notes

<p>About 45 seconds within the opening budget. Show this before the background story so people can scan the QR or open https://github.com/raysapida/terraform_demo, clone the code, and start make prepare. Watching is enough; do not pause for installations.</p>
<p>Make up starts only Floci, pulling its image if missing. Make prepare explicitly pulls the Compose image, starts Floci, and pulls the Lambda runtime, Postgres, Node, Ruby, Docker CLI, registry, Kamal proxy, BuildKit, Ubuntu EC2 image, and Dockerfile frontend. Participants can leave it running in a terminal during the deployment story. It does not provision Terraform resources or deploy the apps.</p>
<p>Make doctor is read-only and lists missing prerequisites. Every stack needs Docker with Compose v2, Terraform, make, and curl. Stack 1's sync also needs AWS CLI. Stack 3's usual route needs host Ruby 4.0.5 and Bundler, Docker Buildx, SSH tools, and OpenSSL; participants can skip it. Stack 4 uses host Node when available and otherwise node:24-slim.</p>
<p>This is image preparation, not a fully offline installation. Terraform providers, npm packages, gems, apt/apk packages, and build layers can still download later. BuildKit has its own cache and can fetch base images again. Download time depends on the connection and existing caches; send make prepare to attendees ahead of the event when possible.</p>
<p>Ports must be free: 4566, 7001–7010, 3020, 3443, 2222, and 5555. Tested on macOS with Apple Silicon; Rails is configured for arm64. The QR on the later Floci slide links to Floci itself, not this repository.</p>

## 3. Where I'm coming from
section: The road here · Heroku
eyebrow: The road here

- Full-stack developer who had to learn the infrastructure underneath my apps.
- Mostly self-taught but with mentors
- Primary background working with an ecommerce SaaS in Rails
- Agency work with small environments of different ages and levels of maintenance.

### notes

About 30 seconds. I'm a full-stack developer who learned the infrastructure underneath the apps I maintained. Most of my background is Rails and small agency environments. The examples include Rails, but the deployment and infrastructure questions apply to JavaScript too.

## 4. Heroku handled the deployment for me
section: The road here
eyebrow: 1 / 7 · Start with a platform

<div class="term"><span class="p">$</span> git push heroku main</div>
<p class="lede" style="margin-top:24px">Once the app and Git remote were configured, the platform handled:</p>
- Preparing the runtime and installing dependencies
- Starting the application and routing requests
- Giving the application a URL

### notes

About 45 seconds. My first framework was Rails, and Heroku was my starting point, back when beginners could use its free tier. I supplied the application and the platform did these jobs. The rest of this short story unpacks what I took responsibility for when I moved to a bare server. It is an explanation of the jobs, not a requirement to leave a working platform.

## 5. The code depends on an environment
section: The road here
eyebrow: 2 / 7 · Libraries and system tools

<div class="code-grid">
  <div>
<pre><span class="c"># Gemfile: a Ruby dependency</span>
source "https://rubygems.org"
gem "mini_magick"</pre>
    <p class="small" style="margin-top:18px">Commit <code>Gemfile</code> and <code>Gemfile.lock</code>, like <code>package.json</code> and its lockfile.</p>
  </div>
  <div class="callout">
    <p>Heroku's Ruby buildpack runs <code>bundle install</code>.</p>
    <p><code>mini_magick</code> is a wrapper. It also needs the <b>ImageMagick</b> program in the environment.</p>
    <p>A dependency list is only part of what makes an app runnable.</p>
  </div>
</div>

### notes

About 60 seconds. This is an addition to an existing Gemfile. Bundler installs Ruby libraries using the lockfile; a native extension may need compatible binaries or build tools. A system program such as ImageMagick has to be available separately. Whether Heroku supplied it depended on the stack. Keep that boundary as the point; the package manager handles libraries, while the environment supplies system tools.
Sources: https://devcenter.heroku.com/articles/bundler ; https://github.com/minimagick/minimagick#requirements

## 6. On a bare server, those jobs become yours
section: The road here
eyebrow: 3 / 7 · Make the hidden work visible

<ol class="steps">
  <li><div><b>Get the code.</b> <span class="d">Connect over SSH and clone the repo.</span></div></li>
  <li><div><b>Install the environment.</b> <span class="d">Runtime, libraries, and database connection.</span></div></li>
  <li><div><b>Start the app.</b> <span class="d">For example, Node or Puma on port 3000.</span></div></li>
  <li><div><b>Route web requests.</b> <span class="d">Nginx or Apache in front, handling HTTPS.</span></div></li>
  <li><div><b>Keep it running.</b> <span class="d">Restart after a crash or reboot.</span></div></li>
  <li><div><b>Give it a name.</b> <span class="d">Point DNS at the endpoint.</span></div></li>
</ol>

### notes

About 60 seconds. A platform was doing these jobs for us. On a fresh Linux server we have to account for each one. For JavaScript, picture an Express or Fastify process behind Nginx, kept alive by systemd or PM2. We will return to DNS after the four app examples. The immediate problem is repeating these steps for the next release.

## 7. A script writes down the steps
section: The road here
eyebrow: 4 / 7 · Repeatable commands

<pre>#!/usr/bin/env bash
set -euo pipefail
ssh deploy@myapp.com &lt;&lt;'EOF'
  cd /var/www/myapp
  git pull origin main
  BUNDLE_DEPLOYMENT=1 bundle install   # or npm ci
  bundle exec rake db:migrate        # or npm run migrate
  sudo systemctl restart myapp
EOF</pre>
<p class="lede" style="margin-top:20px">Now someone else can deploy. But a failed install can leave the live directory half-updated.</p>

### notes

About 60 seconds. This is a useful first improvement, and it may be enough for a small app. The important limitation is that it edits the running release in place. If installation fails after git pull, old processes can be running against new files. We want to prepare the replacement somewhere else and switch only when it is ready. BUNDLE_DEPLOYMENT=1 also works with Bundler 4, unlike the removed bundle install --deployment flag.

## 8. Prepare a release before switching to it
section: The road here
eyebrow: 5 / 7 · Capistrano

<figure>
  <svg viewBox="0 -24 1136 270" role="img" aria-label="Before the flip, the current symlink points at release 20261001120000, which is live, while release 20261003090000 is being prepared next to it. After the flip, current points at 20261003090000, which is live, and the older release is kept as the rollback target.">
    <defs>
      <marker id="a11" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto-start-reverse"><path d="M0 0 L10 5 L0 10 z" fill="currentColor"/></marker>
    </defs>
    <text class="sub" x="0" y="-6">while the new release is prepared</text>
    <text class="sub" x="596" y="-6">after one step: flip current</text>

    <rect class="box b-edge" x="0" y="100" width="150" height="64" rx="6"/>
    <text class="lbl" x="75" y="139" text-anchor="middle">current</text>
    <rect class="box b-compute" x="262" y="20" width="276" height="70" rx="6"/>
    <text class="mono" x="400" y="52" text-anchor="middle">releases/20261001120000</text>
    <text class="sub" x="400" y="76" text-anchor="middle">live</text>
    <rect class="box b-ghost" x="262" y="150" width="276" height="70" rx="6"/>
    <text class="mono" x="400" y="182" text-anchor="middle">releases/20261003090000</text>
    <text class="sub" x="400" y="206" text-anchor="middle">being prepared, next to it</text>
    <path class="wire" d="M150 120 L258 62" marker-end="url(#a11)"/>

    <rect class="box b-edge" x="596" y="100" width="150" height="64" rx="6"/>
    <text class="lbl" x="671" y="139" text-anchor="middle">current</text>
    <rect class="box b-plain" x="858" y="20" width="276" height="70" rx="6"/>
    <text class="mono" x="996" y="52" text-anchor="middle">releases/20261001120000</text>
    <text class="sub" x="996" y="76" text-anchor="middle">kept: the rollback target</text>
    <rect class="box b-compute" x="858" y="150" width="276" height="70" rx="6"/>
    <text class="mono" x="996" y="182" text-anchor="middle">releases/20261003090000</text>
    <text class="sub" x="996" y="206" text-anchor="middle">live</text>
    <path class="wire" d="M746 144 L854 182" marker-end="url(#a11)"/>
    <path class="wire dash" d="M746 120 L854 66" marker-end="url(#a11)"/>
    <text class="arrow-label" x="790" y="56" text-anchor="middle">rollback</text>
  </svg>
  <figcaption>The new version is fully prepared next to the old one, then switched in a single step. Rolling back is the same step in reverse: point <code>current</code> back.</figcaption>
</figure>

### notes

About 75 seconds. Capistrano prepares a timestamped release directory, links shared files, and runs the build before switching current. The previous directory stays available for rollback. The symlink switch is atomic; that does not make the entire deployment or a database migration atomic. Capistrano still expects the runtime and system libraries to be installed on the host. The same release-directory pattern works for a Node application with different build and restart commands.

## 9. Docker packages the environment; Kamal ships it
section: The road here
eyebrow: 6 / 7 · Repeatable runtime and release

<div class="code-grid">
<pre>FROM node:22-slim
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
CMD ["node", "server.js"]</pre>
  <div class="callout">
    <p><b>Build</b> an image containing the app, runtime, and dependencies.</p>
    <p><b>Push</b> the versioned image to a registry.</p>
    <p><b>Kamal</b> starts the new container and switches traffic after its health check passes.</p>
  </div>
</div>
<p class="small" style="margin-top:18px">The release is prepared before the switch. The host still needs Docker and configuration.</p>

### notes

About 75 seconds. Docker moves application environment setup into the image. Kamal coordinates running a new version and switching traffic to it with kamal-proxy. Keep data and secrets outside the image. This does not undo database migrations, patch the host, or create the surrounding network and database. Capistrano remains a reasonable option; keep the trade-off discussion brief here.

## 10. Who creates everything underneath?
section: The road here
eyebrow: 7 / 7 · The question deployment leaves open

- Where do the host, database, and file storage come from?
- Which network paths and permissions connect them?
- Can someone else recreate them, and later delete them?
<div class="fill"><p class="big">Terraform describes the infrastructure those releases need.</p></div>

### notes

About 45 seconds. We can now ship a release, but someone still has to create what it runs on and what it can reach. The same repeatability question now applies to infrastructure. From here, separate provisioning from deploying, then show four app shapes against a local AWS emulator.

## 11. Provisioning is not deploying
section: Terraform on a laptop
eyebrow: Two axes

<table>
  <thead><tr><th>Axis</th><th>Question it answers</th><th>In this talk</th></tr></thead>
  <tbody>
    <tr><td>Provision</td><td>What exists? Buckets, databases, functions, networks</td><td><code>terraform apply</code></td></tr>
    <tr><td>Deploy</td><td>How does my code get onto it?</td><td><code>aws s3 sync</code> · Kamal · a zip upload · <code>vite build</code></td></tr>
  </tbody>
</table>
<div class="fill">
  <p class="big">Every stack tonight has both halves.</p>
</div>

### notes

<p>If you can't say which axis a tool is on, you can't tell whether two tools are alternatives or partners. Terraform and Kamal were never competing.</p>
<p>Stack 1 syncs files after apply. Stack 3 has a whole deploy tool. Stack 2 folds the deploy into apply. Stack 4 builds first, then apply uploads.</p>

## 12. Stock Terraform, pointed at localhost
section: Terraform on a laptop
eyebrow: The laptop cloud

<figure>
  <svg viewBox="0 0 1136 440" role="img" aria-label="Terraform on the laptop sends AWS API calls to Floci on port 4566. Floci stores some resources as records and backs others with real Docker containers. A QR code links to https://floci.io/ for installation instructions.">
    <defs>
      <marker id="a1" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto-start-reverse"><path d="M0 0 L10 5 L0 10 z" fill="currentColor"/></marker>
    </defs>
    <rect class="box b-plain" x="0" y="110" width="230" height="110" rx="6"/>
    <text class="lbl" x="115" y="158" text-anchor="middle">terraform apply</text>
    <text class="sub" x="115" y="184" text-anchor="middle">hashicorp/aws provider</text>

    <path class="wire" d="M230 165 H392" marker-end="url(#a1)"/>
    <text class="arrow-label" x="311" y="150" text-anchor="middle">AWS API calls</text>
    <text class="arrow-label" x="311" y="192" text-anchor="middle">endpoints → :4566</text>

    <rect class="box b-plain" x="396" y="70" width="290" height="190" rx="6"/>
    <text class="lbl" x="541" y="120" text-anchor="middle">Floci</text>
    <text class="sub" x="541" y="146" text-anchor="middle">one container · localhost:4566</text>
    <text class="sub" x="541" y="172" text-anchor="middle">speaks the AWS wire protocol</text>
    <text class="mono" x="541" y="226" text-anchor="middle" fill="currentColor">account 000000000000</text>

    <path class="wire" d="M686 120 H850" marker-end="url(#a1)"/>
    <text class="arrow-label" x="768" y="108" text-anchor="middle">stores</text>
    <rect class="box b-data" x="854" y="40" width="282" height="120" rx="6"/>
    <text class="lbl" x="995" y="82" text-anchor="middle">Records</text>
    <text class="sub" x="995" y="108" text-anchor="middle">S3 · DynamoDB · IAM · VPC</text>
    <text class="sub" x="995" y="132" text-anchor="middle">CloudFront config · SGs</text>

    <path class="wire" d="M686 215 H850" marker-end="url(#a1)"/>
    <text class="arrow-label" x="768" y="203" text-anchor="middle">runs</text>
    <rect class="box b-compute" x="854" y="180" width="282" height="120" rx="6"/>
    <text class="lbl" x="995" y="222" text-anchor="middle">Real containers</text>
    <text class="sub" x="995" y="248" text-anchor="middle">RDS = actual Postgres 15</text>
    <text class="sub" x="995" y="272" text-anchor="middle">Lambda = nodejs:22 image</text>
    <!-- QR: https://floci.io/; error correction Q; four-module white quiet zone. -->
    <rect x="16" y="230" width="198" height="198" fill="#ffffff"/>
    <rect x="40" y="254" width="6" height="6" fill="#000000"/>
    <rect x="46" y="254" width="6" height="6" fill="#000000"/>
    <rect x="52" y="254" width="6" height="6" fill="#000000"/>
    <rect x="58" y="254" width="6" height="6" fill="#000000"/>
    <rect x="64" y="254" width="6" height="6" fill="#000000"/>
    <rect x="70" y="254" width="6" height="6" fill="#000000"/>
    <rect x="76" y="254" width="6" height="6" fill="#000000"/>
    <rect x="88" y="254" width="6" height="6" fill="#000000"/>
    <rect x="94" y="254" width="6" height="6" fill="#000000"/>
    <rect x="124" y="254" width="6" height="6" fill="#000000"/>
    <rect x="130" y="254" width="6" height="6" fill="#000000"/>
    <rect x="136" y="254" width="6" height="6" fill="#000000"/>
    <rect x="148" y="254" width="6" height="6" fill="#000000"/>
    <rect x="154" y="254" width="6" height="6" fill="#000000"/>
    <rect x="160" y="254" width="6" height="6" fill="#000000"/>
    <rect x="166" y="254" width="6" height="6" fill="#000000"/>
    <rect x="172" y="254" width="6" height="6" fill="#000000"/>
    <rect x="178" y="254" width="6" height="6" fill="#000000"/>
    <rect x="184" y="254" width="6" height="6" fill="#000000"/>
    <rect x="40" y="260" width="6" height="6" fill="#000000"/>
    <rect x="76" y="260" width="6" height="6" fill="#000000"/>
    <rect x="88" y="260" width="6" height="6" fill="#000000"/>
    <rect x="94" y="260" width="6" height="6" fill="#000000"/>
    <rect x="112" y="260" width="6" height="6" fill="#000000"/>
    <rect x="118" y="260" width="6" height="6" fill="#000000"/>
    <rect x="124" y="260" width="6" height="6" fill="#000000"/>
    <rect x="136" y="260" width="6" height="6" fill="#000000"/>
    <rect x="148" y="260" width="6" height="6" fill="#000000"/>
    <rect x="184" y="260" width="6" height="6" fill="#000000"/>
    <rect x="40" y="266" width="6" height="6" fill="#000000"/>
    <rect x="52" y="266" width="6" height="6" fill="#000000"/>
    <rect x="58" y="266" width="6" height="6" fill="#000000"/>
    <rect x="64" y="266" width="6" height="6" fill="#000000"/>
    <rect x="76" y="266" width="6" height="6" fill="#000000"/>
    <rect x="94" y="266" width="6" height="6" fill="#000000"/>
    <rect x="112" y="266" width="6" height="6" fill="#000000"/>
    <rect x="118" y="266" width="6" height="6" fill="#000000"/>
    <rect x="136" y="266" width="6" height="6" fill="#000000"/>
    <rect x="148" y="266" width="6" height="6" fill="#000000"/>
    <rect x="160" y="266" width="6" height="6" fill="#000000"/>
    <rect x="166" y="266" width="6" height="6" fill="#000000"/>
    <rect x="172" y="266" width="6" height="6" fill="#000000"/>
    <rect x="184" y="266" width="6" height="6" fill="#000000"/>
    <rect x="40" y="272" width="6" height="6" fill="#000000"/>
    <rect x="52" y="272" width="6" height="6" fill="#000000"/>
    <rect x="58" y="272" width="6" height="6" fill="#000000"/>
    <rect x="64" y="272" width="6" height="6" fill="#000000"/>
    <rect x="76" y="272" width="6" height="6" fill="#000000"/>
    <rect x="94" y="272" width="6" height="6" fill="#000000"/>
    <rect x="100" y="272" width="6" height="6" fill="#000000"/>
    <rect x="112" y="272" width="6" height="6" fill="#000000"/>
    <rect x="130" y="272" width="6" height="6" fill="#000000"/>
    <rect x="136" y="272" width="6" height="6" fill="#000000"/>
    <rect x="148" y="272" width="6" height="6" fill="#000000"/>
    <rect x="160" y="272" width="6" height="6" fill="#000000"/>
    <rect x="166" y="272" width="6" height="6" fill="#000000"/>
    <rect x="172" y="272" width="6" height="6" fill="#000000"/>
    <rect x="184" y="272" width="6" height="6" fill="#000000"/>
    <rect x="40" y="278" width="6" height="6" fill="#000000"/>
    <rect x="52" y="278" width="6" height="6" fill="#000000"/>
    <rect x="58" y="278" width="6" height="6" fill="#000000"/>
    <rect x="64" y="278" width="6" height="6" fill="#000000"/>
    <rect x="76" y="278" width="6" height="6" fill="#000000"/>
    <rect x="148" y="278" width="6" height="6" fill="#000000"/>
    <rect x="160" y="278" width="6" height="6" fill="#000000"/>
    <rect x="166" y="278" width="6" height="6" fill="#000000"/>
    <rect x="172" y="278" width="6" height="6" fill="#000000"/>
    <rect x="184" y="278" width="6" height="6" fill="#000000"/>
    <rect x="40" y="284" width="6" height="6" fill="#000000"/>
    <rect x="76" y="284" width="6" height="6" fill="#000000"/>
    <rect x="100" y="284" width="6" height="6" fill="#000000"/>
    <rect x="112" y="284" width="6" height="6" fill="#000000"/>
    <rect x="136" y="284" width="6" height="6" fill="#000000"/>
    <rect x="148" y="284" width="6" height="6" fill="#000000"/>
    <rect x="184" y="284" width="6" height="6" fill="#000000"/>
    <rect x="40" y="290" width="6" height="6" fill="#000000"/>
    <rect x="46" y="290" width="6" height="6" fill="#000000"/>
    <rect x="52" y="290" width="6" height="6" fill="#000000"/>
    <rect x="58" y="290" width="6" height="6" fill="#000000"/>
    <rect x="64" y="290" width="6" height="6" fill="#000000"/>
    <rect x="70" y="290" width="6" height="6" fill="#000000"/>
    <rect x="76" y="290" width="6" height="6" fill="#000000"/>
    <rect x="88" y="290" width="6" height="6" fill="#000000"/>
    <rect x="100" y="290" width="6" height="6" fill="#000000"/>
    <rect x="112" y="290" width="6" height="6" fill="#000000"/>
    <rect x="124" y="290" width="6" height="6" fill="#000000"/>
    <rect x="136" y="290" width="6" height="6" fill="#000000"/>
    <rect x="148" y="290" width="6" height="6" fill="#000000"/>
    <rect x="154" y="290" width="6" height="6" fill="#000000"/>
    <rect x="160" y="290" width="6" height="6" fill="#000000"/>
    <rect x="166" y="290" width="6" height="6" fill="#000000"/>
    <rect x="172" y="290" width="6" height="6" fill="#000000"/>
    <rect x="178" y="290" width="6" height="6" fill="#000000"/>
    <rect x="184" y="290" width="6" height="6" fill="#000000"/>
    <rect x="94" y="296" width="6" height="6" fill="#000000"/>
    <rect x="106" y="296" width="6" height="6" fill="#000000"/>
    <rect x="112" y="296" width="6" height="6" fill="#000000"/>
    <rect x="124" y="296" width="6" height="6" fill="#000000"/>
    <rect x="130" y="296" width="6" height="6" fill="#000000"/>
    <rect x="136" y="296" width="6" height="6" fill="#000000"/>
    <rect x="46" y="302" width="6" height="6" fill="#000000"/>
    <rect x="76" y="302" width="6" height="6" fill="#000000"/>
    <rect x="82" y="302" width="6" height="6" fill="#000000"/>
    <rect x="88" y="302" width="6" height="6" fill="#000000"/>
    <rect x="100" y="302" width="6" height="6" fill="#000000"/>
    <rect x="112" y="302" width="6" height="6" fill="#000000"/>
    <rect x="142" y="302" width="6" height="6" fill="#000000"/>
    <rect x="178" y="302" width="6" height="6" fill="#000000"/>
    <rect x="184" y="302" width="6" height="6" fill="#000000"/>
    <rect x="46" y="308" width="6" height="6" fill="#000000"/>
    <rect x="64" y="308" width="6" height="6" fill="#000000"/>
    <rect x="94" y="308" width="6" height="6" fill="#000000"/>
    <rect x="112" y="308" width="6" height="6" fill="#000000"/>
    <rect x="118" y="308" width="6" height="6" fill="#000000"/>
    <rect x="130" y="308" width="6" height="6" fill="#000000"/>
    <rect x="154" y="308" width="6" height="6" fill="#000000"/>
    <rect x="160" y="308" width="6" height="6" fill="#000000"/>
    <rect x="166" y="308" width="6" height="6" fill="#000000"/>
    <rect x="172" y="308" width="6" height="6" fill="#000000"/>
    <rect x="178" y="308" width="6" height="6" fill="#000000"/>
    <rect x="46" y="314" width="6" height="6" fill="#000000"/>
    <rect x="52" y="314" width="6" height="6" fill="#000000"/>
    <rect x="70" y="314" width="6" height="6" fill="#000000"/>
    <rect x="76" y="314" width="6" height="6" fill="#000000"/>
    <rect x="94" y="314" width="6" height="6" fill="#000000"/>
    <rect x="100" y="314" width="6" height="6" fill="#000000"/>
    <rect x="118" y="314" width="6" height="6" fill="#000000"/>
    <rect x="124" y="314" width="6" height="6" fill="#000000"/>
    <rect x="130" y="314" width="6" height="6" fill="#000000"/>
    <rect x="136" y="314" width="6" height="6" fill="#000000"/>
    <rect x="142" y="314" width="6" height="6" fill="#000000"/>
    <rect x="160" y="314" width="6" height="6" fill="#000000"/>
    <rect x="166" y="314" width="6" height="6" fill="#000000"/>
    <rect x="178" y="314" width="6" height="6" fill="#000000"/>
    <rect x="184" y="314" width="6" height="6" fill="#000000"/>
    <rect x="40" y="320" width="6" height="6" fill="#000000"/>
    <rect x="46" y="320" width="6" height="6" fill="#000000"/>
    <rect x="64" y="320" width="6" height="6" fill="#000000"/>
    <rect x="82" y="320" width="6" height="6" fill="#000000"/>
    <rect x="100" y="320" width="6" height="6" fill="#000000"/>
    <rect x="112" y="320" width="6" height="6" fill="#000000"/>
    <rect x="118" y="320" width="6" height="6" fill="#000000"/>
    <rect x="148" y="320" width="6" height="6" fill="#000000"/>
    <rect x="154" y="320" width="6" height="6" fill="#000000"/>
    <rect x="166" y="320" width="6" height="6" fill="#000000"/>
    <rect x="184" y="320" width="6" height="6" fill="#000000"/>
    <rect x="40" y="326" width="6" height="6" fill="#000000"/>
    <rect x="46" y="326" width="6" height="6" fill="#000000"/>
    <rect x="76" y="326" width="6" height="6" fill="#000000"/>
    <rect x="94" y="326" width="6" height="6" fill="#000000"/>
    <rect x="100" y="326" width="6" height="6" fill="#000000"/>
    <rect x="118" y="326" width="6" height="6" fill="#000000"/>
    <rect x="136" y="326" width="6" height="6" fill="#000000"/>
    <rect x="148" y="326" width="6" height="6" fill="#000000"/>
    <rect x="154" y="326" width="6" height="6" fill="#000000"/>
    <rect x="184" y="326" width="6" height="6" fill="#000000"/>
    <rect x="40" y="332" width="6" height="6" fill="#000000"/>
    <rect x="46" y="332" width="6" height="6" fill="#000000"/>
    <rect x="58" y="332" width="6" height="6" fill="#000000"/>
    <rect x="70" y="332" width="6" height="6" fill="#000000"/>
    <rect x="82" y="332" width="6" height="6" fill="#000000"/>
    <rect x="88" y="332" width="6" height="6" fill="#000000"/>
    <rect x="94" y="332" width="6" height="6" fill="#000000"/>
    <rect x="100" y="332" width="6" height="6" fill="#000000"/>
    <rect x="106" y="332" width="6" height="6" fill="#000000"/>
    <rect x="112" y="332" width="6" height="6" fill="#000000"/>
    <rect x="118" y="332" width="6" height="6" fill="#000000"/>
    <rect x="130" y="332" width="6" height="6" fill="#000000"/>
    <rect x="136" y="332" width="6" height="6" fill="#000000"/>
    <rect x="154" y="332" width="6" height="6" fill="#000000"/>
    <rect x="178" y="332" width="6" height="6" fill="#000000"/>
    <rect x="40" y="338" width="6" height="6" fill="#000000"/>
    <rect x="58" y="338" width="6" height="6" fill="#000000"/>
    <rect x="70" y="338" width="6" height="6" fill="#000000"/>
    <rect x="76" y="338" width="6" height="6" fill="#000000"/>
    <rect x="82" y="338" width="6" height="6" fill="#000000"/>
    <rect x="88" y="338" width="6" height="6" fill="#000000"/>
    <rect x="118" y="338" width="6" height="6" fill="#000000"/>
    <rect x="130" y="338" width="6" height="6" fill="#000000"/>
    <rect x="142" y="338" width="6" height="6" fill="#000000"/>
    <rect x="154" y="338" width="6" height="6" fill="#000000"/>
    <rect x="160" y="338" width="6" height="6" fill="#000000"/>
    <rect x="166" y="338" width="6" height="6" fill="#000000"/>
    <rect x="178" y="338" width="6" height="6" fill="#000000"/>
    <rect x="184" y="338" width="6" height="6" fill="#000000"/>
    <rect x="40" y="344" width="6" height="6" fill="#000000"/>
    <rect x="58" y="344" width="6" height="6" fill="#000000"/>
    <rect x="70" y="344" width="6" height="6" fill="#000000"/>
    <rect x="82" y="344" width="6" height="6" fill="#000000"/>
    <rect x="94" y="344" width="6" height="6" fill="#000000"/>
    <rect x="100" y="344" width="6" height="6" fill="#000000"/>
    <rect x="106" y="344" width="6" height="6" fill="#000000"/>
    <rect x="112" y="344" width="6" height="6" fill="#000000"/>
    <rect x="124" y="344" width="6" height="6" fill="#000000"/>
    <rect x="130" y="344" width="6" height="6" fill="#000000"/>
    <rect x="142" y="344" width="6" height="6" fill="#000000"/>
    <rect x="154" y="344" width="6" height="6" fill="#000000"/>
    <rect x="166" y="344" width="6" height="6" fill="#000000"/>
    <rect x="172" y="344" width="6" height="6" fill="#000000"/>
    <rect x="184" y="344" width="6" height="6" fill="#000000"/>
    <rect x="40" y="350" width="6" height="6" fill="#000000"/>
    <rect x="52" y="350" width="6" height="6" fill="#000000"/>
    <rect x="64" y="350" width="6" height="6" fill="#000000"/>
    <rect x="70" y="350" width="6" height="6" fill="#000000"/>
    <rect x="76" y="350" width="6" height="6" fill="#000000"/>
    <rect x="82" y="350" width="6" height="6" fill="#000000"/>
    <rect x="106" y="350" width="6" height="6" fill="#000000"/>
    <rect x="124" y="350" width="6" height="6" fill="#000000"/>
    <rect x="136" y="350" width="6" height="6" fill="#000000"/>
    <rect x="142" y="350" width="6" height="6" fill="#000000"/>
    <rect x="148" y="350" width="6" height="6" fill="#000000"/>
    <rect x="154" y="350" width="6" height="6" fill="#000000"/>
    <rect x="160" y="350" width="6" height="6" fill="#000000"/>
    <rect x="172" y="350" width="6" height="6" fill="#000000"/>
    <rect x="88" y="356" width="6" height="6" fill="#000000"/>
    <rect x="100" y="356" width="6" height="6" fill="#000000"/>
    <rect x="106" y="356" width="6" height="6" fill="#000000"/>
    <rect x="112" y="356" width="6" height="6" fill="#000000"/>
    <rect x="124" y="356" width="6" height="6" fill="#000000"/>
    <rect x="136" y="356" width="6" height="6" fill="#000000"/>
    <rect x="160" y="356" width="6" height="6" fill="#000000"/>
    <rect x="40" y="362" width="6" height="6" fill="#000000"/>
    <rect x="46" y="362" width="6" height="6" fill="#000000"/>
    <rect x="52" y="362" width="6" height="6" fill="#000000"/>
    <rect x="58" y="362" width="6" height="6" fill="#000000"/>
    <rect x="64" y="362" width="6" height="6" fill="#000000"/>
    <rect x="70" y="362" width="6" height="6" fill="#000000"/>
    <rect x="76" y="362" width="6" height="6" fill="#000000"/>
    <rect x="88" y="362" width="6" height="6" fill="#000000"/>
    <rect x="100" y="362" width="6" height="6" fill="#000000"/>
    <rect x="106" y="362" width="6" height="6" fill="#000000"/>
    <rect x="124" y="362" width="6" height="6" fill="#000000"/>
    <rect x="136" y="362" width="6" height="6" fill="#000000"/>
    <rect x="148" y="362" width="6" height="6" fill="#000000"/>
    <rect x="160" y="362" width="6" height="6" fill="#000000"/>
    <rect x="184" y="362" width="6" height="6" fill="#000000"/>
    <rect x="40" y="368" width="6" height="6" fill="#000000"/>
    <rect x="76" y="368" width="6" height="6" fill="#000000"/>
    <rect x="100" y="368" width="6" height="6" fill="#000000"/>
    <rect x="112" y="368" width="6" height="6" fill="#000000"/>
    <rect x="118" y="368" width="6" height="6" fill="#000000"/>
    <rect x="124" y="368" width="6" height="6" fill="#000000"/>
    <rect x="136" y="368" width="6" height="6" fill="#000000"/>
    <rect x="160" y="368" width="6" height="6" fill="#000000"/>
    <rect x="178" y="368" width="6" height="6" fill="#000000"/>
    <rect x="184" y="368" width="6" height="6" fill="#000000"/>
    <rect x="40" y="374" width="6" height="6" fill="#000000"/>
    <rect x="52" y="374" width="6" height="6" fill="#000000"/>
    <rect x="58" y="374" width="6" height="6" fill="#000000"/>
    <rect x="64" y="374" width="6" height="6" fill="#000000"/>
    <rect x="76" y="374" width="6" height="6" fill="#000000"/>
    <rect x="94" y="374" width="6" height="6" fill="#000000"/>
    <rect x="100" y="374" width="6" height="6" fill="#000000"/>
    <rect x="106" y="374" width="6" height="6" fill="#000000"/>
    <rect x="124" y="374" width="6" height="6" fill="#000000"/>
    <rect x="130" y="374" width="6" height="6" fill="#000000"/>
    <rect x="136" y="374" width="6" height="6" fill="#000000"/>
    <rect x="142" y="374" width="6" height="6" fill="#000000"/>
    <rect x="148" y="374" width="6" height="6" fill="#000000"/>
    <rect x="154" y="374" width="6" height="6" fill="#000000"/>
    <rect x="160" y="374" width="6" height="6" fill="#000000"/>
    <rect x="172" y="374" width="6" height="6" fill="#000000"/>
    <rect x="184" y="374" width="6" height="6" fill="#000000"/>
    <rect x="40" y="380" width="6" height="6" fill="#000000"/>
    <rect x="52" y="380" width="6" height="6" fill="#000000"/>
    <rect x="58" y="380" width="6" height="6" fill="#000000"/>
    <rect x="64" y="380" width="6" height="6" fill="#000000"/>
    <rect x="76" y="380" width="6" height="6" fill="#000000"/>
    <rect x="94" y="380" width="6" height="6" fill="#000000"/>
    <rect x="100" y="380" width="6" height="6" fill="#000000"/>
    <rect x="118" y="380" width="6" height="6" fill="#000000"/>
    <rect x="124" y="380" width="6" height="6" fill="#000000"/>
    <rect x="130" y="380" width="6" height="6" fill="#000000"/>
    <rect x="136" y="380" width="6" height="6" fill="#000000"/>
    <rect x="142" y="380" width="6" height="6" fill="#000000"/>
    <rect x="148" y="380" width="6" height="6" fill="#000000"/>
    <rect x="178" y="380" width="6" height="6" fill="#000000"/>
    <rect x="184" y="380" width="6" height="6" fill="#000000"/>
    <rect x="40" y="386" width="6" height="6" fill="#000000"/>
    <rect x="52" y="386" width="6" height="6" fill="#000000"/>
    <rect x="58" y="386" width="6" height="6" fill="#000000"/>
    <rect x="64" y="386" width="6" height="6" fill="#000000"/>
    <rect x="76" y="386" width="6" height="6" fill="#000000"/>
    <rect x="94" y="386" width="6" height="6" fill="#000000"/>
    <rect x="100" y="386" width="6" height="6" fill="#000000"/>
    <rect x="106" y="386" width="6" height="6" fill="#000000"/>
    <rect x="118" y="386" width="6" height="6" fill="#000000"/>
    <rect x="130" y="386" width="6" height="6" fill="#000000"/>
    <rect x="136" y="386" width="6" height="6" fill="#000000"/>
    <rect x="166" y="386" width="6" height="6" fill="#000000"/>
    <rect x="172" y="386" width="6" height="6" fill="#000000"/>
    <rect x="184" y="386" width="6" height="6" fill="#000000"/>
    <rect x="40" y="392" width="6" height="6" fill="#000000"/>
    <rect x="76" y="392" width="6" height="6" fill="#000000"/>
    <rect x="88" y="392" width="6" height="6" fill="#000000"/>
    <rect x="136" y="392" width="6" height="6" fill="#000000"/>
    <rect x="148" y="392" width="6" height="6" fill="#000000"/>
    <rect x="154" y="392" width="6" height="6" fill="#000000"/>
    <rect x="160" y="392" width="6" height="6" fill="#000000"/>
    <rect x="184" y="392" width="6" height="6" fill="#000000"/>
    <rect x="40" y="398" width="6" height="6" fill="#000000"/>
    <rect x="46" y="398" width="6" height="6" fill="#000000"/>
    <rect x="52" y="398" width="6" height="6" fill="#000000"/>
    <rect x="58" y="398" width="6" height="6" fill="#000000"/>
    <rect x="64" y="398" width="6" height="6" fill="#000000"/>
    <rect x="70" y="398" width="6" height="6" fill="#000000"/>
    <rect x="76" y="398" width="6" height="6" fill="#000000"/>
    <rect x="100" y="398" width="6" height="6" fill="#000000"/>
    <rect x="118" y="398" width="6" height="6" fill="#000000"/>
    <rect x="124" y="398" width="6" height="6" fill="#000000"/>
    <rect x="136" y="398" width="6" height="6" fill="#000000"/>
    <rect x="166" y="398" width="6" height="6" fill="#000000"/>
    <rect x="184" y="398" width="6" height="6" fill="#000000"/>
    <text class="lbl" x="240" y="346">Install Floci</text>
    <text class="mono" x="240" y="374">https://floci.io/</text>
    <text class="sub" x="240" y="402">Scan for installation instructions</text>
  </svg>
</figure>

### notes

<p>LocalStack's Community edition sunset in March 2026. Floci appeared in direct response: a single native binary on port 4566. No agent, no plugin, no forked provider.</p>
<p>Safety, in thirty seconds: every provider.tf pins endpoints to localhost and uses placeholder test keys, and make preflight refuses to run if anything could reach real AWS.</p>

<p>The QR code opens https://floci.io/, which has installation instructions. For this demo, use the repository's Docker Compose setup and make up; the QR is a reference for installing Floci independently.</p>

## 13. Four apps we'll deploy
section: Terraform on a laptop
eyebrow: The road ahead

<p class="lede" style="margin-bottom:24px">We'll look at what each application needs to run, then create it on the laptop.</p>

<ol class="steps">
  <li><div><b>A static site.</b> <span class="d">HTML, CSS, and JavaScript files for the browser.</span></div></li>
  <li><div><b>A function API.</b> <span class="d">A Node handler that stores and retrieves records when a request arrives.</span></div></li>
  <li><div><b>A server application.</b> <span class="d">Rails with Postgres and file uploads.</span></div></li>
  <li><div><b>A full-stack JavaScript app.</b> <span class="d">TanStack Start with server-rendered pages and browser assets.</span></div></li>
</ol>

### notes

<p>This is the route through the demos. Start with files a browser can download, then an API handler, then a running application with a database, and finally a full-stack JavaScript framework.</p>
<p>For each one, we'll ask what it needs underneath and where provisioning ends and deploying begins. We'll introduce the infrastructure pieces as we encounter them.</p>

## 14. State connects the config to what exists
section: Terraform on a laptop
eyebrow: Terraform in one minute

<dl class="facts">
  <div class="fact"><dt>Config</dt><dd>The resources and relationships you describe in code.</dd></div>
  <div class="fact"><dt>State</dt><dd>Terraform's record linking those resource names to the IDs it manages.</dd></div>
  <div class="fact"><dt>Plan</dt><dd>Compare the configuration with the refreshed resource information and preview changes.</dd></div>
  <div class="fact"><dt>Apply</dt><dd>Make the planned API calls and record the result in state.</dd></div>
</dl>
<p class="lede" style="margin-top:22px">References connect resources. Outputs pass values to the tools that deploy the app.</p>

### notes

About 60 seconds. A resource block names something Terraform manages. The AWS provider makes the API calls; state records which real ID belongs to that resource name. Within a config, reference the resource instead of copying its ID. Outputs expose selected values, which we will use when Kamal reads the database address. Later, separate states explain why two stacks cannot assume that the other one already created a hardcoded ID. State also contains secrets, so it needs protection; sensitive output formatting is not encryption.

## 15. Static site
section: Stack 1 · Static site
eyebrow: <span class="chip">Stack 1</span> The app type
layout: bare

<div class="apptype">
  <div>
    <h1 class="stackname">Static site</h1>
    <p class="lede" style="margin-top:28px">Files built ahead of time and served as-is. Nothing runs on the server when a request arrives.</p>
    <div class="examples"><span>docs &amp; marketing</span><span>Vite / React SPA</span><span>Astro</span><span>Hugo</span><span>Storybook</span></div>
    <div class="examples known"><span class="lead">You may have hosted one on</span><span>Firebase Hosting</span><span>Netlify</span><span>Vercel</span><span>Cloudflare Pages</span><span>GitHub Pages</span></div>
  </div>
  <dl class="facts">
    <div class="fact"><dt>Runs</dt><dd>In the visitor's browser. The server only hands over files.</dd></div>
    <div class="fact"><dt>State</dt><dd>None of its own. Any data comes from someone else's API.</dd></div>
    <div class="fact"><dt>Needs</dt><dd>Somewhere to keep files, and something fast in front of them.</dd></div>
    <div class="fact"><dt>Pick it when</dt><dd>Every visitor gets the same page, or the page fetches what differs.</dd></div>
  </dl>
</div>

### notes

<p>Many developers have shipped one of these by clicking deploy on a platform that handles static hosting for them.</p>
<p>If the build output is a folder of HTML, CSS and JS with no server code, this is your shape, even for a big React SPA.</p>
<p>Firebase Hosting, Netlify, Vercel, Cloudflare Pages and GitHub Pages can handle static hosting for you. Here, we'll build that capability ourselves using S3 and CloudFront.</p>
<p>Netlify and Vercel also support applications that run server code when requests arrive. The build and request handling determine the architecture, rather than the platform name. This stack covers prebuilt files served as-is.</p>

## 16. A private bucket behind a CDN
section: Stack 1 · Static site
eyebrow: <span class="chip">Stack 1</span> Structure

<figure>
  <svg viewBox="0 0 1136 420" role="img" aria-label="The browser requests the page from CloudFront. CloudFront signs its request with origin access control and reads from a private S3 bucket. A bucket policy allows only this distribution. Direct requests to the bucket are refused. Files are uploaded separately with aws s3 sync.">
    <defs>
      <marker id="a2" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto-start-reverse"><path d="M0 0 L10 5 L0 10 z" fill="currentColor"/></marker>
      <marker id="a2no" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto-start-reverse"><path d="M0 0 L10 5 L0 10 z" style="fill:var(--access)"/></marker>
    </defs>
    <rect class="box b-plain" x="0" y="150" width="180" height="90" rx="6"/>
    <text class="lbl" x="90" y="190" text-anchor="middle">Browser</text>
    <text class="sub" x="90" y="214" text-anchor="middle">GET /</text>

    <path class="wire" d="M180 190 H336" marker-end="url(#a2)"/>
    <text class="arrow-label" x="258" y="178" text-anchor="middle">HTTPS</text>

    <rect class="box b-edge" x="340" y="130" width="280" height="130" rx="6"/>
    <text class="lbl" x="480" y="178" text-anchor="middle">CloudFront</text>
    <text class="sub" x="480" y="204" text-anchor="middle">&lt;id&gt;.cloudfront.net</text>
    <text class="sub" x="480" y="228" text-anchor="middle">root object: index.html</text>

    <path class="wire" d="M620 190 H776" marker-end="url(#a2)"/>
    <text class="arrow-label" x="698" y="178" text-anchor="middle">signed (OAC)</text>

    <rect class="box b-data" x="780" y="130" width="300" height="130" rx="6"/>
    <text class="lbl" x="930" y="178" text-anchor="middle">S3 bucket</text>
    <text class="sub" x="930" y="204" text-anchor="middle">private · public access blocked</text>
    <text class="sub" x="930" y="228" text-anchor="middle">no website config</text>

    <rect class="box b-access" x="780" y="310" width="300" height="84" rx="6"/>
    <text class="lbl" x="930" y="345" text-anchor="middle">Bucket policy</text>
    <text class="sub" x="930" y="371" text-anchor="middle">allow only AWS:SourceArn = this CDN</text>
    <path class="wire dash" d="M930 310 V264"/>
    <text class="arrow-label" x="942" y="292">guards</text>

    <rect class="box b-ghost" x="780" y="0" width="300" height="70" rx="6"/>
    <text class="mono" x="930" y="42" text-anchor="middle">aws s3 sync ./site</text>
    <path class="wire dash" d="M930 70 V126" marker-end="url(#a2)"/>
    <text class="arrow-label" x="942" y="104">deploy</text>

    <path class="wire no" d="M90 240 V400 H700 V240 H776" marker-end="url(#a2no)"/>
    <text class="arrow-label" x="395" y="390" text-anchor="middle">direct to the bucket → 403</text>
  </svg>
  <figcaption>Five resources. The CDN is the only way in: the bucket is private, and its policy trusts exactly one distribution.</figcaption>
</figure>

### notes

<p>To serve a static site we need somewhere to keep the files, an HTTPS endpoint through a CDN, and permissions that let the CDN read the files while keeping the bucket private.</p>
<p>Let's describe that setup in Terraform, then upload the site separately. Terraform provisions the hosting infrastructure; uploading the built files deploys the site.</p>
<p>Walk the request left to right. The part people skip is the bottom arrow: nobody can read the bucket directly, not even with a website endpoint.</p>
<p>Origin access control replaced origin access identity in 2022. Tutorials still show OAI, and it still works, which is how old patterns survive.</p>

## 17. A bucket and a file in two commands
section: Stack 1 · Static site
eyebrow: <span class="chip">Stack 1</span> By hand first

<div class="cols">
<div class="term"><span class="p">$</span> aws --endpoint-url http://localhost:4566 \
  s3 mb s3://done-by-hand
make_bucket: done-by-hand

<span class="p">$</span> aws --endpoint-url http://localhost:4566 \
  s3 cp index.html s3://done-by-hand/
upload: ./index.html

<span class="ok">The file is stored.</span>        <span class="p"># about 30 seconds</span></div>
  <ul class="points tight">
    <li>The AWS CLI points at Floci on <code>localhost:4566</code>.</li>
    <li>No Terraform. No apply. No HCL.</li>
    <li>This is how most of us started, and it is not wrong.</li>
    <li>That is one box of the diagram. Terraform builds the rest.</li>
  </ul>
</div>

### notes

<p>Do this live. It needs no build, no warm-up and no network, so it is the safest demo in the deck.</p>
<p>This is the standard AWS CLI. The explicit --endpoint-url sends both commands to Floci on the laptop. Use the demo's test credentials and us-east-1 region.</p>
<p>These commands create a bucket and upload a file. They do not configure website access or a CDN. Then run stack 1 to build the complete hosting setup from the diagram.</p>
<p>A line to say: "Could I just point a domain at this bucket? Almost: turn on website hosting, make it public, name the bucket after the domain, and add a DNS record. But you'd get HTTP only. HTTPS on your own domain needs a CDN in front, which is why stack 1 has one."</p>
<p>What that takes on real AWS (checked against AWS's docs, 2026-10-12):</p>
<p>1. Turn on static website hosting with index.html as the index document. That gives the bucket a separate website endpoint, http://BUCKET.s3-website-us-east-1.amazonaws.com. The normal S3 endpoint does not serve an index document: a request to the bucket root returns a list of object keys, and errors come back as XML, not HTML.</p>
<p>2. Make it public, which is two steps: turn off Block Public Access (on the bucket, and on the account if it is on there), then add a bucket policy allowing s3:GetObject to "*". The website endpoint only serves publicly readable content. Since April 2023, buckets created through the CLI, SDKs, APIs or CloudFormation get Block Public Access on and ACLs disabled by default; console-made buckets already did. It applies to new buckets only.</p>
<p>3. Name the bucket exactly after the hostname, such as www.example.com. AWS says the bucket names must match the domain name exactly. Bucket names are global, so if someone else owns that name, you cannot use it.</p>
<p>4. Point DNS at the website endpoint: a CNAME for www, and for the bare domain a Route 53 alias record, which is what AWS's tutorial uses. (A CNAME is not allowed at the bare domain; that is a DNS rule, stated from memory, not from AWS's docs.)</p>
<p>Then it is HTTP only. AWS: "Amazon S3 website endpoints do not support HTTPS." For HTTPS AWS points to CloudFront or Amplify Hosting. Some domains will not load over HTTP at all: .dev and .app are on browsers' HSTS preload list, so browsers force HTTPS for them.</p>
<p>The two approaches are alternatives, not layers. CloudFront's docs say a bucket set up as a website endpoint cannot use origin access control: CloudFront has to treat it as an ordinary custom origin, which means the bucket stays public. So it is either a public website bucket, HTTP only unless a CDN is in front, or what stack 1 builds: a private bucket that only its CloudFront distribution can read. (https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html)</p>
<p>Keep this about real AWS. Whether Floci emulates S3 website endpoints is untested, and Floci does not enforce bucket privacy by default, so a demo there would make public look like it does not matter.</p>
<p>Sources: https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteEndpoints.html ; https://docs.aws.amazon.com/AmazonS3/latest/userguide/website-hosting-custom-domain-walkthrough.html ; https://aws.amazon.com/about-aws/whats-new/2023/04/amazon-s3-security-best-practices-buckets-default ; https://en.wikipedia.org/wiki/.dev</p>

## 18. Run Stack 1 and open the site
section: Stack 1 · Static site
eyebrow: <span class="chip">Stack 1</span> Try it

<p class="lede" style="margin-bottom:18px">From the repository root, run:</p>

<div class="term"><span class="p">$</span> make site
...
Preflight passed.
...
distribution_id = "E23QVEUMXAS598"
...
<span class="ok">HTTP 200, 722 bytes</span></div>

<p class="small" style="margin-top:18px">Output above is an example. Use your printed <code>distribution_id</code> in this browser URL:</p>

<pre>http://&lt;your-distribution-id&gt;.cloudfront.localhost:4566/</pre>

<p class="small" style="margin-top:14px"><b>Expected page:</b> “Served by a CDN that does not exist”. No hosts-file edits needed.</p>

### notes

<p>Run make site from the repository root. It starts Floci, checks the local endpoints, provisions the bucket and distribution with Terraform, uploads the site files, and checks the response with curl. On a repeat run, the upload may print nothing if the files are unchanged.</p>
<p>Look for HTTP 200 and the distribution_id in the output. The sample ID and byte count are illustrative; use the ID from your own run. Floci assigns that ID when it creates the distribution, and recreating the distribution can change it.</p>
<p>For example, distribution_id E23QVEUMXAS598 opens at http://e23qveumxas598.cloudfront.localhost:4566/. Use HTTP and port 4566 for this local demo. The .localhost suffix sends the browser to the laptop, and Floci selects the distribution from the hostname. No sudo or /etc/hosts changes are needed.</p>
<p>The browser should show the heading “Served by a CDN that does not exist” and explain that the page lives in a private S3 bucket behind a CloudFront distribution, all on the laptop. This demonstrates local content delivery through Floci's CloudFront emulation.</p>

## 19. Inspect Stack 1 with the AWS CLI
section: Stack 1 · Static site
eyebrow: <span class="chip">Stack 1</span> Try it

<p class="small" style="margin-bottom:12px">After <code>make site</code>, set demo credentials in your terminal:</p>

<pre>export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1 AWS_PAGER=""</pre>

<div class="cols">
  <div>
    <h3>List the deployed files</h3>
    <div class="term"><span class="p">$</span> aws --endpoint-url http://localhost:4566 \
  s3 ls s3://sacjs-static-site/</div>
    <p class="small" style="margin-top:14px"><b>Expect:</b> <code>index.html</code> with its upload time and size.</p>
  </div>
  <div>
    <h3>List the CDN distributions</h3>
    <div class="term"><span class="p">$</span> aws --endpoint-url http://localhost:4566 \
  cloudfront list-distributions \
  --query 'DistributionList.Items[].{ID:Id,Status:Status}' \
  --output table</div>
    <p class="small" style="margin-top:14px"><b>Expect:</b> a table with your distribution ID and <code>Deployed</code> status.</p>
  </div>
</div>

### notes

<p>These are standard AWS CLI commands, explicitly pointed at Floci on localhost:4566. Set the test credentials and region in this terminal: the make recipe's environment does not carry back into the calling shell. AWS_PAGER disables the interactive pager so the results stay visible.</p>
<p>The S3 listing shows the file uploaded by make site. The CloudFront query keeps the output focused on distribution IDs and statuses. Other distributions can appear if participants have already run another stack; their IDs and file timestamps will differ from the presenter's.</p>
<p>Optional: inspect the bucket policy to connect this CLI exercise to the permission diagram. From the repository root, with the same demo environment:</p>

```bash
aws --endpoint-url http://localhost:4566 \
  s3api get-bucket-policy --bucket sacjs-static-site \
  --query Policy --output text
```

<p>The policy grants CloudFront read access with AWS:SourceArn restricted to this distribution. Retrieving the policy demonstrates its stored configuration; Floci's enforcement behavior is covered separately in this stack.</p>

## 20. The ledger
section: Stack 1 · Static site
eyebrow: <span class="chip">Stack 1</span> terraform plan

<div class="ledger" style="--rows:9">
  <div class="group ink-data">Data</div>
  <div class="res">aws_s3_bucket.site<em>Holds the built files</em></div>
  <div class="res">aws_s3_bucket_public_access_block.site<em>Locks the bucket against public ACLs and policies</em></div>
  <div class="group ink-edge">Edge</div>
  <div class="res">aws_cloudfront_origin_access_control.site<em>How the CDN proves who it is when it reads S3</em></div>
  <div class="res">aws_cloudfront_distribution.site<em>The CDN: HTTPS, caching, index.html at /</em></div>
  <div class="group ink-access">Access</div>
  <div class="res">aws_s3_bucket_policy.site<em>The one line of trust between them</em></div>
</div>
<div class="plan-summary">
  <span><b>Plan: 5 to add</b>, 0 to change, 0 to destroy.</span>
  <span>main.tf · 143 lines</span>
  <span>network resources · 0</span>
</div>

### notes

<p>143 lines includes the comments, which are most of it. The resources themselves fit on one screen.</p>
<p>Note what's absent: no VPC, no subnets, no servers. Hold that for stack 3.</p>

<p>To show all five exist, ask Floci directly. Always use ./scripts/awslocal (the AWS CLI pinned to Floci), never bare aws. Read the names from Terraform instead of copying IDs:</p>

```
B=$(terraform -chdir=stacks/01-static-site/terraform output -raw bucket_name)
D=$(terraform -chdir=stacks/01-static-site/terraform output -raw distribution_id)

terraform -chdir=stacks/01-static-site/terraform state list           # the five, as Terraform sees them
./scripts/awslocal s3api head-bucket --bucket $B                      # 1 bucket
./scripts/awslocal s3api get-public-access-block --bucket $B          # 2 all four switches true
./scripts/awslocal cloudfront list-origin-access-controls             # 3 sacjs-static-site-oac, signing always
./scripts/awslocal cloudfront get-distribution --id $D                # 4 Deployed, origin = the bucket, uses that OAC
./scripts/awslocal s3api get-bucket-policy --bucket $B                # 5 GetObject for this distribution only
./scripts/awslocal s3 ls s3://$B/                                     # the files: uploaded by make site, not Terraform
```

<p>The cross-references are the point: the distribution names the bucket and the OAC's ID, and the policy names the distribution.</p>
<p>Exists is not the same as enforced. An anonymous read straight from the bucket, skipping CloudFront, returns 200 on Floci; on real AWS the public access block and the policy would make it 403. Floci stores both but only evaluates them with its enforcement settings on (docs/FINDINGS.md).</p>

```
curl -s -o /dev/null -w "%{http_code}" http://localhost:4566/sacjs-static-site/index.html
```

<p>Checked 2026-10-12: all five present, curl returned 200. If you use variables, set them as above; a command stored in one variable and run as $TF does not work in zsh.</p>

## 21. One line of trust
section: Stack 1 · Static site
eyebrow: <span class="chip">Stack 1</span> The code that matters

<div class="code-grid">
<pre><span class="k">resource</span> <span class="s">"aws_s3_bucket_policy"</span> <span class="s">"site"</span> {
bucket = aws_s3_bucket.site.id
policy = jsonencode({
  Statement = [{
    Effect    = <span class="s">"Allow"</span>
    Principal = { Service = <span class="s">"cloudfront.amazonaws.com"</span> }
    Action    = <span class="s">"s3:GetObject"</span>
    Resource  = <span class="s">"${aws_s3_bucket.site.arn}/*"</span>
    Condition = {
      StringEquals = {
        <span class="hl"><span class="s">"AWS:SourceArn"</span> = aws_cloudfront_distribution.site.arn</span>
      }
    }
  }]
})
}</pre>
  <div class="callout">
    <p class="label">Why it matters</p>
    <p>"CloudFront may read" would let <em>any</em> distribution in any account read your bucket. The condition narrows it to this one.</p>
    <p>No ID is typed. Terraform wires the distribution's ARN in, so the policy can't point at last month's CDN.</p>
  </div>
</div>

### notes

<p>The highlighted line is the difference between "private" and "private unless someone else also uses CloudFront".</p>
<p>Everything is a reference, not a pasted ID, which is the same rule that fixes the Act III bug later.</p>
<p>Why the condition matters, from AWS's docs (checked 2026-10-12): a policy that trusts a service principal such as cloudfront.amazonaws.com "is only authorizing the AWS service principal, and not the actor who configured the calling service". Without the condition, a distribution someone else set up could use CloudFront's trust to read your bucket. AWS calls this the confused deputy problem and recommends aws:SourceArn (or aws:SourceAccount) wherever a service principal is granted access. CloudFront's own guide says to use the condition so CloudFront can read the bucket "only when the request is on behalf of the CloudFront distribution".</p>
<p>Say this about Floci: it stores this policy but does not enforce it unless its enforcement settings are on (FLOCI_SERVICES_S3_ENFORCE_AUTH and FLOCI_SERVICES_IAM_ENFORCEMENT_ENABLED, both off by default). Delete the resource and the demo site still works; an anonymous read of the bucket returns 200. On real AWS, delete it and the site returns 403. One sentence is enough: "Floci keeps this but does not check it; AWS does."</p>
<p>Sources: https://docs.aws.amazon.com/IAM/latest/UserGuide/confused-deputy.html ; https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html ; docs/FINDINGS.md for the Floci behavior.</p>

## 22. Where provisioning ends and deployment begins
section: Stack 1 · Static site
eyebrow: <span class="chip">Stack 1</span> Demo

<div class="cols">
<div class="term"><span class="p">$</span> make site     <span class="p"># is these two:</span>

<span class="p">$</span> terraform apply   <span class="p"># provision</span>
bucket_name     = "sacjs-static-site"
distribution_id = "ENR6K826BATSPY"

<span class="p">$</span> ./scripts/awslocal s3 sync \
    site/ s3://sacjs-static-site
upload: site/index.html   <span class="p"># deploy</span>

<span class="ok">HTTP 200, 722 bytes</span>          <span class="p"># ~50s</span></div>
  <ul class="edges">
    <li><span class="tag real">Real</span><span>Deleting a distribution means disabling it first. The provider does it for you, and it takes a minute.</span></li>
    <li><span class="tag edge-case">Emulator</span><span>Delete the bucket policy and the site still loads. Floci stores the policy but doesn't evaluate it unless enforcement flags are on.</span></li>
    <li><span class="tag edge-case">Emulator</span><span>AWS provider 5.x crashes on this stack against Floci; 6.x doesn't. Emulators have edges.</span></li>
  </ul>
</div>

### notes

<p>Do not run make site a second time here. Refer back to the successful run: Terraform describes the hosting infrastructure; the upload deploys the built files. This gives us a working local URL. We'll return to custom domains after the other examples.</p>
<p>Optional: open https://&lt;id&gt;.cloudfront.net through the local Caddy for a real padlock.</p>
<p>What make site runs, as you would type it from the repository root (checked by hand in a clean shell, 2026-10-12):</p>

```
cd stacks/01-static-site/terraform
terraform init
terraform apply                                   # provision: the five resources
cd ../../..
./scripts/awslocal s3 sync stacks/01-static-site/site \
  "s3://$(terraform -chdir=stacks/01-static-site/terraform output -raw bucket_name)" --delete
                                                  # deploy: the files

D=$(terraform -chdir=stacks/01-static-site/terraform output -raw distribution_id)
curl --resolve "$D.cloudfront.net:4566:127.0.0.1" "http://$D.cloudfront.net:4566/"
```

<p>./scripts/awslocal is the plain AWS CLI with --endpoint-url http://localhost:4566 added, so nothing can reach real AWS. On real AWS the deploy is the same command with plain aws. make site adds -auto-approve to the apply; typed by hand, terraform apply shows the plan and asks first, which is worth showing once. The bucket name comes from terraform output rather than being typed: the deploy step reads what provisioning made, the same seam stack 3's Kamal uses.</p>

## 23. Function API
section: Stack 2 · Lambda + DynamoDB
eyebrow: <span class="chip">Stack 2</span> The app type
layout: bare

<div class="apptype">
  <div>
    <h1 class="stackname">Function API</h1>
    <p class="lede" style="margin-top:28px">A handler invoked when a request arrives. The platform manages its execution environment; you do not keep an application server running.</p>
    <div class="examples"><span>webhooks</span><span>JSON APIs</span><span>form handlers</span><span>cron jobs</span><span>glue between services</span></div>
    <div class="examples known"><span class="lead">You may know it as</span><span>Cloudflare Workers</span><span>Vercel Functions</span><span>Netlify Functions</span><span>Supabase Edge Functions</span></div>
  </div>
  <dl class="facts">
    <div class="fact"><dt>Runs</dt><dd>Per request, in a container AWS starts and stops for you.</dd></div>
    <div class="fact"><dt>State</dt><dd>Nowhere in the function. A key-value table holds it.</dd></div>
    <div class="fact"><dt>Needs</dt><dd>A function, a table, a URL, and permission for each to touch the next.</dd></div>
    <div class="fact"><dt>Pick it when</dt><dd>Traffic is spiky or small, and work fits in seconds.</dd></div>
  </dl>
</div>

### notes

<p>The demo is a 64-line Node handler: POST adds a message, GET lists them. No framework.</p>
<p>Honest caveat: long-running work, websockets and heavy relational data push you toward a server, which is stack 3, next.</p>
<p>Not every platform makes permissions the hard part. On Cloudflare Workers access is a binding declared in the config file: no role, no policy, nothing to over-grant. Worth saying, so the IAM slide does not read as universal.</p>

## 24. No fence, just permissions
section: Stack 2 · Lambda + DynamoDB
eyebrow: <span class="chip">Stack 2</span> Structure

<figure>
  <svg viewBox="0 0 1136 430" role="img" aria-label="A client calls a function URL, allowed by a two-statement resource policy. The URL invokes a Lambda function, which assumes an execution role allowing PutItem and Scan on one DynamoDB table and writes to its own log group. There is no VPC.">
    <defs>
      <marker id="a4" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto-start-reverse"><path d="M0 0 L10 5 L0 10 z" fill="currentColor"/></marker>
    </defs>
    <rect class="box b-ghost" x="0" y="0" width="420" height="96" rx="6"/>
    <text class="lbl" x="210" y="42" text-anchor="middle" style="fill:var(--muted)">VPC · subnets · security groups</text>
    <text class="sub" x="210" y="70" text-anchor="middle">none of it: AWS runs the function somewhere you never see</text>

    <rect class="box b-plain" x="0" y="190" width="160" height="80" rx="6"/>
    <text class="lbl" x="80" y="236" text-anchor="middle">client</text>
    <path class="wire" d="M160 230 H256" marker-end="url(#a4)"/>
    <text class="arrow-label" x="208" y="218" text-anchor="middle">HTTPS</text>

    <rect class="box b-compute" x="260" y="180" width="210" height="100" rx="6"/>
    <text class="lbl" x="365" y="222" text-anchor="middle">Function URL</text>
    <text class="sub" x="365" y="248" text-anchor="middle">auth: NONE</text>

    <rect class="box b-access" x="260" y="320" width="210" height="96" rx="6"/>
    <text class="lbl" x="365" y="356" text-anchor="middle">Resource policy</text>
    <text class="sub" x="365" y="380" text-anchor="middle">InvokeFunctionUrl</text>
    <text class="sub" x="365" y="400" text-anchor="middle">+ InvokeFunction via URL</text>
    <path class="wire dash" d="M365 320 V284"/>

    <path class="wire" d="M470 230 H566" marker-end="url(#a4)"/>
    <text class="arrow-label" x="518" y="218" text-anchor="middle">invoke</text>

    <rect class="box b-compute" x="570" y="160" width="250" height="140" rx="6"/>
    <text class="lbl" x="695" y="206" text-anchor="middle">Lambda</text>
    <text class="sub" x="695" y="232" text-anchor="middle">nodejs22.x · index.mjs</text>
    <text class="sub" x="695" y="256" text-anchor="middle">no endpoint config</text>

    <rect class="box b-compute" x="570" y="20" width="250" height="76" rx="6"/>
    <text class="lbl" x="695" y="54" text-anchor="middle">Log group</text>
    <text class="sub" x="695" y="78" text-anchor="middle">7-day retention</text>
    <path class="wire" d="M695 160 V100" marker-end="url(#a4)"/>
    <text class="arrow-label" x="707" y="136">writes</text>

    <rect class="box b-access" x="570" y="336" width="250" height="80" rx="6"/>
    <text class="lbl" x="695" y="370" text-anchor="middle">Execution role</text>
    <text class="sub" x="695" y="394" text-anchor="middle">PutItem + Scan, one table</text>
    <path class="wire dash" d="M695 336 V304"/>
    <text class="arrow-label" x="707" y="326">assumes</text>

    <path class="wire" d="M820 230 H916" marker-end="url(#a4)"/>
    <text class="arrow-label" x="868" y="218" text-anchor="middle">Put / Scan</text>

    <rect class="box b-data" x="920" y="170" width="216" height="120" rx="6"/>
    <text class="lbl" x="1028" y="214" text-anchor="middle">DynamoDB</text>
    <text class="sub" x="1028" y="240" text-anchor="middle">on-demand</text>
    <text class="sub" x="1028" y="262" text-anchor="middle">key: id</text>
  </svg>
  <figcaption>Every arrow needs a permission. The brick boxes are the part you'll get wrong, and on this emulator the part you can't test.</figcaption>
</figure>

### notes

<p>No network to build: no VPC, no subnets, no security groups. What's left to get wrong is who may do what: the resource policy on the way in, the role on the way out.</p>
<p>The handler has no endpoint, region or credentials in it. On AWS they come from the role; on Floci, the runtime injects AWS_ENDPOINT_URL.</p>
<p>Hold that thought: in stack 3, the network comes back and is most of the file.</p>

## 25. The ledger
section: Stack 2 · Lambda + DynamoDB
eyebrow: <span class="chip">Stack 2</span> terraform plan

<div class="ledger" style="--rows:8">
  <div class="group ink-access">Access · 5</div>
  <div class="res">aws_iam_role.function<em>Trust: only lambda.amazonaws.com</em></div>
  <div class="res">aws_iam_role_policy.table<em>Two actions on one table ARN</em></div>
  <div class="res">aws_iam_role_policy.logs<em>Its own log group, not every group</em></div>
  <div class="res">aws_lambda_permission.url</div>
  <div class="res">aws_lambda_permission.invoke_via_url<em>The one older tutorials miss</em></div>
  <div class="group ink-compute">Compute · 3</div>
  <div class="res">aws_cloudwatch_log_group.function</div>
  <div class="res">aws_lambda_function.api<em>Zipped by Terraform from function/</em></div>
  <div class="res">aws_lambda_function_url.api</div>
  <div class="group ink-data">Data · 1</div>
  <div class="res">aws_dynamodb_table.messages</div>
</div>
<div class="plan-summary">
  <span><b>Plan: 9 to add</b>, 0 to change, 0 to destroy.</span>
  <span>main.tf · 166 lines</span>
  <span>network resources · 0</span>
</div>

### notes

<p>Five of nine are permissions. The data layer is a single resource whose whole schema is its key.</p>
<p>There is no separate deploy step here: change the handler and the zip hash changes, so the next apply uploads new code.</p>

## 26. "Public" still needs two permissions
section: Stack 2 · Lambda + DynamoDB
eyebrow: <span class="chip">Stack 2</span> The code that matters

<div class="code-grid">
<pre><span class="k">resource</span> <span class="s">"aws_lambda_function_url"</span> <span class="s">"api"</span> {
function_name      = aws_lambda_function.api.function_name
authorization_type = <span class="s">"NONE"</span>
}

<span class="k">resource</span> <span class="s">"aws_lambda_permission"</span> <span class="s">"url"</span> {
action                 = <span class="s">"lambda:InvokeFunctionUrl"</span>
principal              = <span class="s">"*"</span>
function_url_auth_type = <span class="s">"NONE"</span>
}

<span class="k">resource</span> <span class="s">"aws_lambda_permission"</span> <span class="s">"invoke_via_url"</span> {
action                   = <span class="s">"lambda:InvokeFunction"</span>
principal                = <span class="s">"*"</span>
<span class="hl">invoked_via_function_url = true</span>
}</pre>
  <div class="callout">
    <p class="label">Since October 2025</p>
    <p>New function URLs need both statements, even with auth <code>NONE</code>. Miss the second and callers get <b>403 Forbidden</b>.</p>
    <p>The console and SAM add both for you. Terraform, the CLI and CloudFormation don't, so anything copied from an older tutorial is missing one.</p>
    <p class="small">docs.aws.amazon.com/lambda/latest/dg/urls-auth.html</p>
  </div>
</div>

### notes

<p>This is the October 2025 trap. Works in the console, 403 from Terraform, and the difference is one boolean.</p>
<p>Floci accepts either version, so the emulator won't catch it for you.</p>

## 27. 31 seconds from nothing
section: Stack 2 · Lambda + DynamoDB
eyebrow: <span class="chip">Stack 2</span> Demo

<div class="cols">
<div class="term"><span class="p">$</span> make lambda
Apply complete! Resources: 9 added

═══ POST ═══
{ "id": "097f7256-…",
"message": "hello from make lambda" }

═══ GET ═══
<span class="ok">{ "count": 1, "messages": [ … ] }</span></div>
  <ul class="edges">
    <li><span class="tag edge-case">Emulator</span><span>Floci runs Lambda in a Docker container. The first invoke pulls a 618 MB <code>nodejs:22</code> image, and you can watch it in <code>docker ps</code>.</span></li>
    <li><span class="tag edge-case">Emulator</span><span>By default Floci accepts any IAM policy, so <code>dynamodb:*</code> on <code>*</code> "works" too.</span></li>
    <li><span class="tag edge-case">Emulator</span><span>With enforcement on, Floci denies the <em>scoped</em> policy and allows the wildcard: it checks every table as <code>table/*</code>. This emulator cannot reliably validate the scoped policy.</span></li>
  </ul>
</div>

### notes

<p>Say the last point plainly: the scoped policy is the intended AWS configuration, but this emulator cannot reliably validate it. Keep the correctly scoped policy and explain the limitation.</p>
<p>If time allows: edit the handler, re-apply, show source_code_hash driving the redeploy.</p>

## 28. Talk to it, then read its logs
section: Stack 2 · Lambda + DynamoDB
eyebrow: <span class="chip">Stack 2</span> Demo

<div class="term"><span class="p">$</span> curl -X POST -d '{"message":"hi from the room"}' $URL
{ "id": "d9b8dcff-…", "message": "hi from the room" }    <span class="p"># 201</span>
<span class="p">$</span> curl -X POST -d nope $URL
{ "error": "body must be JSON" }                         <span class="p"># 400</span>

<span class="p">$</span> ./scripts/awslocal logs tail /aws/lambda/sacjs-lambda --since 5m
01:16:48  4e628318…  INFO  <span class="ok">{"method":"POST","status":201,"ms":27}</span>
01:16:48  27ada18f…  INFO  <span class="ok">{"method":"POST","status":400,"ms":1}</span></div>
<ul class="edges" style="margin-top:24px">
  <li><span class="tag real">Real</span><span>The log group and the function's permission to write to it are two of the nine resources in the ledger. No logging service to set up.</span></li>
  <li><span class="tag edge-case">Emulator</span><span><code>logs tail --follow</code> prints nothing on Floci. Run <code>tail</code> after the requests instead.</span></li>
</ul>

### notes

<p>Do this live with two commands, in one terminal or two. Anyone can call the function: the URL is public, so a laptop in the room could POST to it too if it were reachable.</p>

```
URL=$(terraform -chdir=stacks/02-lambda/terraform output -raw function_url)
curl -X POST -d '{"message":"hi from the room"}' $URL     # 201, a new message
curl -X POST -d nope $URL                                 # 400, body must be JSON
curl $URL                                                 # 200, the list
./scripts/awslocal logs tail /aws/lambda/sacjs-lambda --since 5m --format short
```

<p>Each request writes one JSON line: method, status, milliseconds. Lambda sends anything the function prints to stdout or stderr to CloudWatch Logs, in the log group Terraform created (/aws/lambda/sacjs-lambda, kept 7 days). The long ID on each line is the request ID; the same ID ties a log line to one invocation.</p>
<p>The handler logs on purpose: one console.log in index.mjs. Without it there is nothing to read, because Floci does not add the START, END and REPORT lines real Lambda writes around each invocation (those platform lines are from memory of real AWS; Floci's absence of them was observed).</p>
<p>On Floci, logs tail --follow showed nothing, not even recent history, while plain tail works; checked with AWS CLI 2.36 on 2026-10-12. For a live view, rerun tail, or: watch -n2 ./scripts/awslocal logs tail /aws/lambda/sacjs-lambda --since 5m --format short. Floci-only shortcut: docker logs -f on the floci-aws-sacjs-lambda container shows the same lines.</p>

## 29. Server app
section: Stack 3 · Rails + Postgres + S3
eyebrow: <span class="chip">Stack 3</span> The app type
layout: bare

<div class="apptype">
  <div>
    <h1 class="stackname">Server app</h1>
    <p class="lede" style="margin-top:28px">A long-running process that renders pages, talks to a relational database, and stores what users upload.</p>
    <div class="examples"><span>Rails</span><span>Django</span><span>Laravel</span><span>Express + Prisma</span><span>Phoenix</span></div>
    <div class="examples known"><span class="lead">You may know it as</span><span>Heroku</span><span>Render</span><span>Railway</span><span>Fly.io</span><span>DO App Platform</span></div>
  </div>
  <dl class="facts">
    <div class="fact"><dt>Runs</dt><dd>On a machine you keep alive, all day, waiting for requests.</dd></div>
    <div class="fact"><dt>State</dt><dd>Rows in Postgres, files in object storage. The server itself is disposable.</dd></div>
    <div class="fact"><dt>Needs</dt><dd>A host, a private database, a bucket, and a way to keep them apart.</dd></div>
    <div class="fact"><dt>Pick it when</dt><dd>You want transactions, background jobs and a monolith you can reason about.</dd></div>
  </dl>
</div>

### notes

<p>The demo app is Rails 8.1 with one ActiveStorage upload page, but nothing about this shape is Ruby-specific. Swap in Django or Express and the Terraform is identical.</p>
<p>The defining trait: a process that is always on, and a database that must never be reachable from the internet.</p>
<p>On a platform this is a host plus managed Postgres plus object storage, wired for you. Kamal on any plain server is the do-it-yourself version, and it is portable: on Hetzner or DigitalOcean, Terraform makes a server and a firewall and Kamal deploys to its IP.</p>

## 30. Most of it is the fence
section: Stack 3 · Rails + Postgres + S3
eyebrow: <span class="chip">Stack 3</span> Structure

<figure>
  <svg viewBox="0 0 1136 440" role="img" aria-label="A VPC contains a public subnet with the app host running kamal-proxy and Rails, and private subnets with RDS Postgres. The browser enters through an internet gateway. Rails connects to Postgres on port 5432 and to an S3 bucket outside the VPC using an IAM access key. Kamal deploys to the host over SSH.">
    <defs>
      <marker id="a3" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto-start-reverse"><path d="M0 0 L10 5 L0 10 z" fill="currentColor"/></marker>
    </defs>
    <!-- VPC -->
    <rect class="zone" x="236" y="20" width="664" height="400" rx="8" style="stroke:var(--network)"/>
    <text class="mono" x="256" y="46" style="fill:var(--network)">VPC 10.20.0.0/16</text>
    <rect class="zone" x="266" y="64" width="300" height="330" rx="6" style="stroke:var(--network)" stroke-dasharray="5 5"/>
    <text class="mono" x="282" y="88" style="fill:var(--network)">public subnet</text>
    <rect class="zone" x="600" y="64" width="276" height="330" rx="6" style="stroke:var(--network)" stroke-dasharray="5 5"/>
    <text class="mono" x="616" y="88" style="fill:var(--network)">private subnets ×2 AZs</text>

    <!-- IGW -->
    <rect class="box b-network" x="212" y="196" width="48" height="48" rx="4"/>
    <text class="mono" x="236" y="225" text-anchor="middle">IGW</text>

    <!-- Browser -->
    <rect class="box b-plain" x="0" y="180" width="160" height="80" rx="6"/>
    <text class="lbl" x="80" y="226" text-anchor="middle">Browser</text>
    <path class="wire" d="M160 220 H208" marker-end="url(#a3)"/>

    <!-- Host -->
    <rect class="box b-compute" x="290" y="112" width="252" height="232" rx="6"/>
    <text class="lbl" x="416" y="144" text-anchor="middle">App host</text>
    <text class="sub" x="416" y="166" text-anchor="middle">app security group</text>
    <rect class="box b-plain" x="310" y="184" width="212" height="54" rx="4"/>
    <text class="mono" x="416" y="216" text-anchor="middle">kamal-proxy :80</text>
    <rect class="box b-plain" x="310" y="266" width="212" height="54" rx="4"/>
    <text class="mono" x="416" y="298" text-anchor="middle">Rails · Puma :3000</text>
    <path class="wire" d="M260 220 H306" marker-end="url(#a3)"/>
    <path class="wire" d="M416 238 V262" marker-end="url(#a3)"/>

    <!-- RDS -->
    <rect class="box b-data" x="624" y="200" width="228" height="110" rx="6"/>
    <text class="lbl" x="738" y="240" text-anchor="middle">RDS Postgres 15</text>
    <text class="sub" x="738" y="264" text-anchor="middle">db SG: 5432 from app SG</text>
    <text class="sub" x="738" y="286" text-anchor="middle">publicly_accessible = false</text>
    <path class="wire" d="M522 293 H572 V260 H620" marker-end="url(#a3)"/>
    <text class="arrow-label" x="564" y="284" text-anchor="end">5432</text>

    <!-- S3 -->
    <rect class="box b-data" x="966" y="64" width="170" height="96" rx="6"/>
    <text class="lbl" x="1051" y="104" text-anchor="middle">S3 uploads</text>
    <text class="sub" x="1051" y="128" text-anchor="middle">private bucket</text>
    <path class="wire" d="M522 128 H 590 V36 H1051 V60" marker-end="url(#a3)"/>
    <text class="arrow-label" x="780" y="56" text-anchor="middle">ActiveStorage · S3 API</text>

    <!-- IAM -->
    <rect class="box b-access" x="966" y="280" width="170" height="96" rx="6"/>
    <text class="lbl" x="1051" y="320" text-anchor="middle">IAM user + key</text>
    <text class="sub" x="1051" y="344" text-anchor="middle">scoped to the bucket</text>
    <path class="wire dash" d="M1051 280 V164"/>
    <text class="arrow-label" x="1063" y="228">allows</text>

    <!-- Kamal -->
    <rect class="box b-ghost" x="0" y="336" width="190" height="70" rx="6"/>
    <text class="mono" x="95" y="377" text-anchor="middle">kamal deploy</text>
    <path class="wire dash" d="M190 371 H416 V348" marker-end="url(#a3)"/>
    <text class="arrow-label" x="300" y="364" text-anchor="middle">SSH</text>
  </svg>
  <figcaption>Postgres is one box. The indigo around it is what keeps it private, and it's most of the file.</figcaption>
</figure>

### notes

<p>RDS insists on two subnets in two availability zones, even for a single instance. That surprises people every time.</p>
<p>The database security group admits Postgres from the app's security group, a reference not an IP range. Same rule as the Act III fix: refer to the thing, never copy its address.</p>
<p>The app host is in the Terraform as it would be on real AWS: an aws_instance in the public subnet, behind the app security group, which admits 80 and 443 from anywhere and 22 (Kamal's SSH) from one address. Floci creates the instance too, as an Ubuntu container. On the laptop Kamal still deploys to a stand-in container with sshd and Docker, because Docker inside Floci's instance needs extra steps that are not wired up yet.</p>
<p>Floci does not enforce security groups by default, so on the laptop the fence is described, not tested. On real AWS it is what keeps Postgres private.</p>
<p>Compare stack 2, which had no fence at all: nine resources and not one of them network.</p>

## 31. Public is a route, not a setting
section: Stack 3 · Rails + Postgres + S3
eyebrow: <span class="chip">Stack 3</span> The code that matters

<div class="code-grid">
<pre><span class="k">resource</span> <span class="s">"aws_internet_gateway"</span> <span class="s">"main"</span> {
  vpc_id = aws_vpc.main.id
}

<span class="k">resource</span> <span class="s">"aws_route_table"</span> <span class="s">"public"</span> {
  vpc_id = aws_vpc.main.id
  route {
    <span class="hl">cidr_block = <span class="s">"0.0.0.0/0"</span></span>
    <span class="hl">gateway_id = aws_internet_gateway.main.id</span>
  }
}

<span class="k">resource</span> <span class="s">"aws_route_table_association"</span> <span class="s">"public"</span> {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}</pre>
  <div class="callout">
    <p class="label">Three ideas</p>
    <p><b>A route makes it public.</b> The public subnet sends everything else to the internet gateway. The private ones have no such route.</p>
    <p><b>A security group makes it allowed.</b> Postgres admits 5432 only from the app's group, by reference, not by address.</p>
    <p><b>Two zones, because RDS asks.</b> One database still needs subnets in two availability zones.</p>
  </div>
</div>

### notes

<p>The line to say: public versus private is three resources, a gateway, a route and an association. Delete the route and the public subnet becomes private. There is no "public" checkbox on a subnet; map_public_ip_on_launch only hands out public addresses, it is the route that makes them reachable.</p>
<p>Addresses, in one sentence: the VPC is 10.20.0.0/16, about 65,000 private addresses that are yours. Each subnet is a /24 slice of it, 256 addresses, of which AWS keeps 5. cidrsubnet() carves the slices so nobody types them: public 10.20.1.0/24, private 10.20.10.0/24 and 10.20.11.0/24.</p>
<p>Availability zones: a subnet lives in one zone, roughly one data center. RDS wants a subnet group across at least two zones even for one instance, which is why there are two private subnets.</p>
<p>Routes and security groups answer different questions. A route decides whether traffic can get somewhere; a security group decides whether it is allowed in once it arrives. Security groups are stateful: allow the request in and the reply goes back out on its own.</p>
<p>If the route points at a gateway that is detached or deleted, the route stays but its state becomes blackhole, and matching traffic is dropped (EC2 API reference, Route: blackhole means the target is not available, for example a detached gateway). Nothing answers, so connections hang and time out. With the route and gateway but no public IP, an instance still cannot get out: the internet gateway only translates for instances with a public address, which is why the public subnet sets map_public_ip_on_launch.</p>
<p>A diagnostic worth giving the room: if a connection hangs and then times out, packets are being dropped, so look at routes and security groups, which both drop silently. If it says "connection refused" straight away, you reached the machine and nothing is listening on that port, so look at the app. On Floci neither shows, because routes and security groups are not enforced.</p>
<p>The database has three independent layers: private subnets with no route out, publicly_accessible = false, and a security group that only admits the app. Any one of them keeps it off the internet.</p>
<p>What is deliberately missing: a NAT gateway. Private subnets have no outbound internet, and the database needs none. An app in a private subnet would need one to reach the internet, and NAT gateways bill by the hour. Small setups often keep the app in the public subnet behind a security group instead, as this stack does.</p>
<p>If someone asks why the app is public: "Here the app is public behind a security group, which is fine for one server. At work you'll usually see it private, behind a load balancer, with a NAT gateway so it can still reach out." The load balancer becomes the only public thing, which shrinks what can be attacked and spreads traffic across servers. The NAT gateway lets private servers pull images and call APIs without being reachable. This stack skips both because it is one server, and both add resources and monthly cost.</p>
<p>On Floci all of this is stored but not enforced by default, so the network is described here, not tested. The ledger notes have describe-subnets and describe-route-tables commands that show it exists.</p>

## 32. The ledger
section: Stack 3 · Rails + Postgres + S3
eyebrow: <span class="chip">Stack 3</span> terraform plan

<div class="ledger" style="--rows:11">
  <div class="group ink-network">Network · 9</div>
  <div class="res">aws_vpc.main</div>
  <div class="res">aws_internet_gateway.main</div>
  <div class="res">aws_route_table.public</div>
  <div class="res">aws_route_table_association.public</div>
  <div class="res">aws_subnet.public</div>
  <div class="res">aws_subnet.private[0], [1]<em>Two AZs, because RDS requires it</em></div>
  <div class="res">aws_security_group.app</div>
  <div class="res">aws_security_group.db<em>5432 from the app SG only</em></div>
  <div class="group ink-compute">Compute · 2</div>
  <div class="res">aws_instance.app, aws_key_pair.deploy</div>
  <div class="group ink-data">Data · 5</div>
  <div class="res">aws_db_subnet_group.main</div>
  <div class="res">random_password.db<em>No default password in git</em></div>
  <div class="res">aws_db_instance.main</div>
  <div class="res">aws_s3_bucket.uploads</div>
  <div class="res">aws_s3_bucket_public_access_block.uploads</div>
  <div class="group ink-access">Access · 3</div>
  <div class="res">aws_iam_user.app</div>
  <div class="res">aws_iam_access_key.app</div>
  <div class="res">aws_iam_user_policy.app_uploads</div>
</div>
<div class="plan-summary">
  <span><b>Plan: 19 to add</b>, 0 to change, 0 to destroy.</span>
  <span>main.tf · 312 lines</span>
  <span>RDS: ~85s of a ~1.5 min apply</span>
</div>

### notes

<p>Count the indigo: nine of nineteen. The thing you actually care about, Postgres, is one line in the data group.</p>
<p>The password is generated, but it still sits in terraform.tfstate in plain text. sensitive = true only hides it from your terminal.</p>
<p>To show these exist, ask Floci directly (checked 2026-10-12; read-only, pinned to Floci):</p>

```
A=./scripts/awslocal
tf() { terraform -chdir=stacks/03-rails/terraform "$@"; }
VPC=$(tf state show -no-color aws_vpc.main | awk -F'"' '/^ *id /{print $2; exit}')

tf state list                                                        # the 19, plus data.aws_ami.ubuntu (a lookup, not a resource)
$A ec2 describe-vpcs --vpc-ids $VPC --query 'Vpcs[0].CidrBlock'      # 10.20.0.0/16
$A ec2 describe-subnets --filters Name=vpc-id,Values=$VPC \
  --query 'Subnets[].[Tags[?Key==`Name`]|[0].Value,CidrBlock,AvailabilityZone]' --output text
                                                                     # public 10.20.1.0/24 + private ×2 in 1a and 1b
$A ec2 describe-route-tables --filters Name=vpc-id,Values=$VPC \
  --query 'RouteTables[].Routes[?GatewayId!=`local`]'                # 0.0.0.0/0 → igw-…
$A ec2 describe-security-groups --filters Name=vpc-id,Values=$VPC \
  --query 'SecurityGroups[].[GroupName,IpPermissions]'               # app: 22, 80, 443 · db: 5432 from the app SG's ID
$A ec2 describe-instances --filters Name=vpc-id,Values=$VPC \
  --query 'Reservations[].Instances[].[InstanceId,State.Name,InstanceType,ImageId,KeyName]' --output text
                                                                     # running t4g.small, Ubuntu 24.04 arm64, the deploy key
$A rds describe-db-instances \
  --query 'DBInstances[0].[Engine,EngineVersion,PubliclyAccessible]' # postgres 15.17 False
$A s3api get-public-access-block --bucket sacjs-rails-uploads        # all four true
$A iam get-user-policy --user-name sacjs-rails-app --policy-name uploads-bucket
                                                                     # ListBucket + Get/Put/DeleteObject, this bucket only
```

<p>The instance is real in Floci (an Ubuntu container) but idle: Kamal deploys to the stand-in host. The VPC ID is read from Terraform's state, so no ID is copied by hand.</p>

## 33. The seam, read from state
section: Stack 3 · Rails + Postgres + S3
eyebrow: <span class="chip">Stack 3</span> The code that matters

<div class="code-grid">
<pre><span class="c"># app/config/deploy.yml</span>
&lt;% tf = -&gt;(name) {
<span class="hl">`terraform -chdir=../terraform output -raw #{name}`</span>.strip
} %&gt;

<span class="k">env</span>:
<span class="k">clear</span>:
  DB_HOST: &lt;%= tf.(<span class="s">"db_host"</span>) %&gt;
  DB_PORT: &lt;%= tf.(<span class="s">"db_port"</span>) %&gt;
  S3_BUCKET: &lt;%= tf.(<span class="s">"s3_bucket"</span>) %&gt;
<span class="k">secret</span>:
  - DB_PASSWORD      <span class="c"># .kamal/secrets reads</span>
  - AWS_ACCESS_KEY_ID <span class="c"># these from terraform too</span></pre>
  <div class="callout">
    <p class="label">What the real repo did</p>
<pre><span class="k">servers</span>:
<span class="k">web</span>:
  - 203.0.113.10
<span class="c"># POSTGRES_HOST: terraform-2025…rds…</span></pre>
    <p>An IP and another stack's RDS hostname, pasted by hand. It works until the day either one changes.</p>
  </div>
</div>

### notes

<p>Terraform outputs the values; Kamal reads them at deploy time. Nothing typed, nothing pasted, and .kamal/secrets holds commands rather than values, so it's safe to commit.</p>
<p>On the right, a real production deploy.yml (sanitized): the seam held together by copy and paste.</p>
<p>One value is still typed: the server. deploy.yml lists 127.0.0.1, the stand-in host. Terraform now outputs app_host_ip, so on real AWS the seam closes completely with:</p>

```
servers:
  web:
    hosts:
      - <%= tf.("app_host_ip") %>
```

<p>On the laptop the host stays 127.0.0.1, because Kamal deploys to the stand-in, not to Floci's instance (docs/FINDINGS.md).</p>
<p>Not every secret comes from Terraform. SECRET_KEY_BASE is read from a file (host/state/secret_key_base) generated once by make rails, because it is an app secret, not infrastructure. Terraform owns the values that describe infrastructure: addresses, names, and the credentials it created.</p>
<p>terraform output reads the state file, not AWS. With Floci paused it still answered in under half a second. So it is fast and works offline, but it shows what the last apply recorded; if someone changes the infrastructure outside Terraform, the output is stale until the next apply.</p>
<p>The machine that deploys needs Terraform and access to the state. On a laptop that is the local terraform.tfstate. For a team or a CI job it is the reason to keep state in a shared, encrypted remote backend (for example S3 with locking), since the state also holds the database password in plain text.</p>

## 34. Upload, redeploy, no dropped requests
section: Stack 3 · Rails + Postgres + S3
eyebrow: <span class="chip">Stack 3</span> Demo

<div class="cols">
<div class="term"><span class="p">$</span> make rails
═══ provision ═══
Apply complete! Resources: 19 added
═══ kamal deploy ═══
First web container is healthy
Finished all in 9.8 seconds

<span class="p">$</span> while true; do curl -so /dev/null \
  -w '%{http_code}\n' :3020/up; done
<span class="ok">200 200 200 200 200 200 200 …</span></div>
  <ul class="edges">
    <li><span class="tag real">Real</span><span>kamal-proxy switches traffic only when the new container passes <code>/up</code>. 47 of 47 checks returned 200 during a deploy.</span></li>
    <li><span class="tag edge-case">Emulator</span><span>The database SG says "app only". A container in no security group connects anyway: Floci stores SGs, it doesn't enforce them.</span></li>
    <li><span class="tag edge-case">Emulator</span><span>Terraform creates the EC2 host, but Kamal deploys to a stand-in container: Floci can't route traffic into Docker inside its instances. Images go to a local registry, so no Docker Hub account.</span></li>
  </ul>
</div>

### notes

<p>Upload a file first: object appears in Floci S3, row in Postgres (make rails-psql). Then change a line in the view and redeploy with the curl loop running.</p>
<p>First deploy is ~2 minutes (registry, proxy, build). After that about ten seconds.</p>
<p>If someone asks why Kamal does not deploy to the EC2 instance Terraform made: "I tried. Kamal got all the way to a healthy container inside Floci's instance, but Floci's port forwarding can't reach it from the laptop, and the first setup took eleven minutes." The full step-by-step is in docs/FINDINGS.md (Kamal into the EC2 instance, 2026-10-12).</p>

## 35. Full-stack framework
section: Stack 4 · TanStack Start
eyebrow: <span class="chip">Stack 4</span> The app type
layout: bare

<div class="apptype">
  <div>
    <h1 class="stackname">Full-stack framework</h1>
    <p class="lede" style="margin-top:28px">One TypeScript codebase that renders on the server and hydrates in the browser. The build splits it in two.</p>
    <div class="examples"><span>TanStack Start</span><span>Next.js</span><span>Nuxt</span><span>SvelteKit</span><span>Remix</span></div>
    <div class="examples known"><span class="lead">You may know it as</span><span>Vercel</span><span>Netlify</span><span>Cloudflare</span><span>Railway</span></div>
  </div>
  <dl class="facts">
    <div class="fact"><dt>Runs</dt><dd>HTML rendered in a function per request; JS and CSS from files.</dd></div>
    <div class="fact"><dt>State</dt><dd>Whatever the server code reads. This demo keeps none.</dd></div>
    <div class="fact"><dt>Needs</dt><dd>Stack 1 for the files, stack 2 for the server, and one thing to join them.</dd></div>
    <div class="fact"><dt>Pick it when</dt><dd>You want SEO-friendly HTML and a React app in the same repo.</dd></div>
  </dl>
</div>

### notes

<p>TanStack Start 1.168 with Nitro's aws_lambda preset. The preset is one word in vite.config.ts.</p>
<p>This is the payoff of the order: nothing in this stack is new except the thing that joins the two halves.</p>
<p>These are the platforms this build is usually pointed at. TanStack's own docs name Cloudflare Workers, Netlify and Railway as official hosting partners, and Nitro's preset is the one-word switch: aws_lambda for ours, others for them. Same app, different preset, different Terraform, or none at all.</p>

## 36. Stack 1 + stack 2, one join
section: Stack 4 · TanStack Start
eyebrow: <span class="chip">Stack 4</span> Structure

<figure>
  <svg viewBox="0 0 1136 420" role="img" aria-label="vite build writes .output/public, uploaded to a private S3 bucket, and .output/server, zipped into a Lambda. The browser requests CloudFront, which routes /assets/* to S3 through origin access control and every other path to the Lambda through its function URL.">
    <defs>
      <marker id="a5" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto-start-reverse"><path d="M0 0 L10 5 L0 10 z" fill="currentColor"/></marker>
    </defs>
    <rect class="box b-ghost" x="0" y="0" width="300" height="72" rx="6"/>
    <text class="mono" x="150" y="32" text-anchor="middle">vite build</text>
    <text class="sub" x="150" y="56" text-anchor="middle">Nitro preset: aws_lambda</text>
    <path class="wire dash" d="M300 26 H802 V130" marker-end="url(#a5)"/>
    <text class="arrow-label" x="560" y="18" text-anchor="middle">.output/public → aws_s3_object</text>
    <path class="wire dash" d="M300 54 H1060 V302" marker-end="url(#a5)"/>
    <text class="arrow-label" x="930" y="46" text-anchor="middle">.output/server → zip</text>

    <rect class="box b-plain" x="0" y="206" width="150" height="80" rx="6"/>
    <text class="lbl" x="75" y="252" text-anchor="middle">Browser</text>
    <path class="wire" d="M150 246 H216" marker-end="url(#a5)"/>

    <rect class="box b-edge" x="220" y="150" width="340" height="190" rx="6"/>
    <text class="lbl" x="390" y="188" text-anchor="middle">CloudFront</text>
    <text class="sub" x="390" y="210" text-anchor="middle">two origins, two behaviors</text>
    <rect class="box b-plain" x="240" y="228" width="300" height="42" rx="4"/>
    <text class="mono" x="256" y="255">/assets/*  → S3 · cache 1y</text>
    <rect class="box b-plain" x="240" y="280" width="300" height="42" rx="4"/>
    <text class="mono" x="256" y="307">default    → Lambda · no cache</text>

    <path class="wire" d="M540 249 H620 V180 H686" marker-end="url(#a5)"/>
    <text class="arrow-label" x="630" y="170">OAC</text>
    <rect class="box b-data" x="690" y="130" width="224" height="100" rx="6"/>
    <text class="lbl" x="802" y="172" text-anchor="middle">S3 assets</text>
    <text class="sub" x="802" y="196" text-anchor="middle">private · stack 1's shape</text>

    <path class="wire" d="M540 301 H620 V352 H686" marker-end="url(#a5)"/>
    <text class="arrow-label" x="630" y="376">Host rewritten</text>
    <rect class="box b-compute" x="690" y="302" width="224" height="100" rx="6"/>
    <text class="lbl" x="802" y="344" text-anchor="middle">Function URL</text>
    <text class="sub" x="802" y="368" text-anchor="middle">stack 2's shape</text>
    <path class="wire" d="M914 352 H956" marker-end="url(#a5)"/>
    <rect class="box b-compute" x="960" y="302" width="176" height="100" rx="6"/>
    <text class="lbl" x="1048" y="344" text-anchor="middle">Lambda SSR</text>
    <text class="sub" x="1048" y="368" text-anchor="middle">renders React</text>
  </svg>
  <figcaption>The build decides the architecture: two output folders, two origins. Assets upload before the function changes, so new HTML never points at missing CSS.</figcaption>
</figure>

### notes

<p>Point at the colors: teal and ochre on the top path are stack 1, plum on the bottom path is stack 2. CloudFront's second behavior is the only new idea.</p>
<p>"Host rewritten": the SSR behavior forwards every viewer header except Host. A function URL routes on its own hostname, so forwarding the browser's Host makes Lambda reject every request.</p>

## 37. The ledger
section: Stack 4 · TanStack Start
eyebrow: <span class="chip">Stack 4</span> terraform plan

<div class="ledger" style="--rows:10">
  <div class="group ink-data">From stack 1 · assets</div>
  <div class="res">aws_s3_bucket.assets</div>
  <div class="res">aws_s3_bucket_public_access_block.assets</div>
  <div class="res">aws_s3_object.assets["assets/…"] ×3<em>Fingerprinted, cached for a year</em></div>
  <div class="res">aws_cloudfront_origin_access_control.assets</div>
  <div class="res">aws_s3_bucket_policy.assets</div>
  <div class="group ink-compute">From stack 2 · server</div>
  <div class="res">aws_iam_role.ssr</div>
  <div class="res">aws_iam_role_policy.logs</div>
  <div class="res">aws_cloudwatch_log_group.ssr</div>
  <div class="res">aws_lambda_function.ssr<em>Nitro's .output/server, 512 MB</em></div>
  <div class="res">aws_lambda_function_url.ssr</div>
  <div class="res">aws_lambda_permission.url, .invoke_via_url</div>
  <div class="group ink-edge">New</div>
  <div class="res">aws_cloudfront_distribution.site<em>Two origins, two behaviors</em></div>
</div>
<div class="plan-summary">
  <span><b>Plan: 15 to add</b>, 0 to change, 0 to destroy.</span>
  <span>main.tf · 295 lines</span>
  <span>new ideas · 1</span>
</div>

### notes

<p>Seven from stack 1's shape, seven from stack 2's, one new. A modern full-stack framework deploys onto resources this room watched get created twenty minutes ago.</p>

## 38. Two behaviors, one managed policy
section: Stack 4 · TanStack Start
eyebrow: <span class="chip">Stack 4</span> The code that matters

<div class="code-grid">
<pre><span class="k">ordered_cache_behavior</span> {
path_pattern     = <span class="s">"/assets/*"</span>
target_origin_id = <span class="s">"assets"</span>
cache_policy_id  = <span class="s">"658327ea-…"</span> <span class="c"># CachingOptimized</span>
}

<span class="k">default_cache_behavior</span> {
target_origin_id = <span class="s">"ssr"</span>
allowed_methods  = [<span class="s">"GET"</span>, <span class="s">"HEAD"</span>, <span class="s">"OPTIONS"</span>,
                    <span class="s">"PUT"</span>, <span class="s">"POST"</span>, <span class="s">"PATCH"</span>, <span class="s">"DELETE"</span>]
cache_policy_id  = <span class="s">"4135ea2d-…"</span> <span class="c"># CachingDisabled</span>
<span class="hl">origin_request_policy_id = <span class="s">"b689b0a8-…"</span></span>
<span class="c"># AllViewerExceptHostHeader</span>
}</pre>
  <div class="callout">
    <p class="label">The classic CloudFront → Lambda bug</p>
    <p>Forward all viewer headers and you forward <code>Host</code>. The function URL routes on its own hostname, sees <code>abc.cloudfront.net</code>, and refuses.</p>
    <p>These IDs are literal, but AWS owns them and they're identical in every account. That's not the cross-state hardcoding bug; that one's next.</p>
  </div>
</div>

### notes

<p>Assets: cached at the edge for a year, safe because Nitro fingerprints filenames. Server renders: never cached, every method allowed.</p>

## 39. HTML from a function, CSS from a bucket
section: Stack 4 · TanStack Start
eyebrow: <span class="chip">Stack 4</span> Demo

<div class="cols">
<div class="term"><span class="p">$</span> make tanstack
[nitro] Building (preset: aws-lambda)
.output/server/index.mjs  978 kB
Apply complete! Resources: 15 added

page:  <span class="ok">HTTP 200, 2740 bytes (Lambda)</span>
asset: <span class="ok">HTTP 200, text/css (S3)</span>
                           <span class="p"># ~52s</span></div>
  <ul class="edges">
    <li><span class="tag real">Real</span><span>Reload the page: the request count climbs while the Lambda container stays warm. Wait, and it resets. That's a cold start.</span></li>
    <li><span class="tag edge-case">Emulator</span><span>Floci's CloudFront forwards only GET, HEAD and OPTIONS to Lambda, and drops the query string. So this app renders on the server only: no client-side server functions.</span></li>
    <li><span class="tag edge-case">Emulator</span><span>CloudFront refuses loopback origins by default. One allowlist line in <code>docker-compose.yml</code>.</span></li>
  </ul>
</div>

### notes

<p>Network tab: the HTML plus three assets, nothing else. No server-function calls during hydration.</p>
<p>The Terraform is right for real AWS. The app is shaped around the emulator, and saying so out loud is the honest version.</p>

## 40. Where the resources went
section: Four shapes
eyebrow: After the four demos

<div class="legend" aria-hidden="true">
  <span class="ink-network"><b class="t">Network</b></span>
  <span class="ink-edge"><b class="t">Edge / CDN</b></span>
  <span class="ink-compute"><b class="t">Compute</b></span>
  <span class="ink-data"><b class="t">Data</b></span>
  <span class="ink-access"><b class="t">Access / IAM</b></span>
</div>
<figure>
  <svg viewBox="0 0 1136 400" role="img" aria-label="Resources per stack by category. Static site 5: edge 2, data 2, access 1. Lambda 9: compute 3, data 1, access 5. Rails 19: network 9, compute 2, data 5, access 3. TanStack Start 15: edge 2, compute 3, data 5, access 5.">
    <!-- scale: 0..19 resources → x 250..1105 (45px per resource) -->
    <line class="grid" x1="250" y1="12" x2="250" y2="318"/>
    <line class="grid" x1="475" y1="12" x2="475" y2="318"/>
    <line class="grid" x1="700" y1="12" x2="700" y2="318"/>
    <line class="grid" x1="925" y1="12" x2="925" y2="318"/>
    <text class="tick" x="250" y="344" text-anchor="middle">0</text>
    <text class="tick" x="475" y="344" text-anchor="middle">5</text>
    <text class="tick" x="700" y="344" text-anchor="middle">10</text>
    <text class="tick" x="925" y="344" text-anchor="middle">15</text>

    <text class="lbl" x="230" y="52" text-anchor="end">Static site</text>
    <rect class="seg-edge" x="250" y="24" width="90" height="44"/><text class="seg-num" x="295" y="52" text-anchor="middle">2</text>
    <rect class="seg-data" x="340" y="24" width="90" height="44"/><text class="seg-num" x="385" y="52" text-anchor="middle">2</text>
    <rect class="seg-access" x="430" y="24" width="45" height="44"/><text class="seg-num" x="452" y="52" text-anchor="middle">1</text>
    <text class="tick" x="489" y="52">5</text>

    <text class="lbl" x="230" y="128" text-anchor="end">Lambda</text>
    <rect class="seg-compute" x="250" y="100" width="135" height="44"/><text class="seg-num" x="317" y="128" text-anchor="middle">3</text>
    <rect class="seg-data" x="385" y="100" width="45" height="44"/><text class="seg-num" x="407" y="128" text-anchor="middle">1</text>
    <rect class="seg-access" x="430" y="100" width="225" height="44"/><text class="seg-num" x="542" y="128" text-anchor="middle">5</text>
    <text class="tick" x="669" y="128">9</text>

    <text class="lbl" x="230" y="204" text-anchor="end">Rails</text>
    <rect class="seg-network" x="250" y="176" width="405" height="44"/><text class="seg-num" x="452" y="204" text-anchor="middle">9</text>
    <rect class="seg-compute" x="655" y="176" width="90" height="44"/><text class="seg-num" x="700" y="204" text-anchor="middle">2</text>
    <rect class="seg-data" x="745" y="176" width="225" height="44"/><text class="seg-num" x="857" y="204" text-anchor="middle">5</text>
    <rect class="seg-access" x="970" y="176" width="135" height="44"/><text class="seg-num" x="1037" y="204" text-anchor="middle">3</text>
    <text class="tick" x="1119" y="204">19</text>

    <text class="lbl" x="230" y="280" text-anchor="end">TanStack Start</text>
    <rect class="seg-edge" x="250" y="252" width="90" height="44"/><text class="seg-num" x="295" y="280" text-anchor="middle">2</text>
    <rect class="seg-compute" x="340" y="252" width="135" height="44"/><text class="seg-num" x="407" y="280" text-anchor="middle">3</text>
    <rect class="seg-data" x="475" y="252" width="225" height="44"/><text class="seg-num" x="587" y="280" text-anchor="middle">5</text>
    <rect class="seg-access" x="700" y="252" width="225" height="44"/><text class="seg-num" x="812" y="280" text-anchor="middle">5</text>
    <text class="tick" x="939" y="280">15</text>
    <text class="sub" x="675" y="382" text-anchor="middle">Number of Terraform resources</text>
  </svg>
  <figcaption>Numbers inside each color count that category; the number at the end is the total. Only the Rails demo defines a VPC and subnets.</figcaption>
</figure>

### notes

<p>Now that we have seen the resources in all four demos, compare their mix. Each number counts things Terraform manages, including buckets, policies, and permission rules; it is not a server count, a cost, or a performance measurement.</p>
<p>Read Rails as an example: nine network resources, two compute resources (the host and its key pair), five data resources, and three access resources make nineteen total. More than half its configuration is networking. The Lambda stack defines no VPC or subnets, and access is its biggest slice.</p>
<p>TanStack Start uses categories we already saw in the static site and the function API. A new framework combined familiar pieces.</p>

## 41. Four stacks
section: Four shapes
eyebrow: Side by side

<table>
  <thead><tr><th></th><th>Static site</th><th>Function API</th><th>Server app</th><th>Full-stack</th></tr></thead>
  <tbody>
    <tr><td>Resources</td><td>5</td><td>9</td><td>19</td><td>15</td></tr>
    <tr><td>Mostly</td><td class="ink-edge">CDN + one policy</td><td class="ink-access">IAM</td><td class="ink-network">Network</td><td>Stacks 1 + 2, joined</td></tr>
    <tr><td>Deploy</td><td><code>aws s3 sync</code></td><td>none: apply uploads the zip</td><td>Kamal, ~10s</td><td><code>vite build</code>, then apply</td></tr>
    <tr><td>Local setup time</td><td>50s</td><td>31s</td><td>~4 min</td><td>52s</td></tr>
    <tr><td>Can't test here</td><td>Bucket policy</td><td>Least privilege</td><td>Security groups</td><td>POST through the CDN</td></tr>
  </tbody>
</table>

### notes

<p>The setup timings are local make-target runs, not Lambda cold-start latency or AWS provisioning guarantees. Read the "Mostly" row out loud. That's the talk in four words.</p>
<p>The bottom row is honest: every stack has one thing the emulator stores but doesn't enforce. Learn the shape here; learn the policies against the real thing.</p>

## 42. A records and CNAMEs
section: The front door
eyebrow: Pointing a name at your app

<figure>
  <svg viewBox="0 -24 1136 320" role="img" aria-label="Two lookups. An A record points app.yourapp.com straight at the address 203.0.113.10, your host. A CNAME points www.yourapp.com at another name, d111abcdef8.cloudfront.net, which is then looked up again and resolves through an A record to 198.51.100.7, a CloudFront edge.">
    <defs>
      <marker id="a9" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto-start-reverse"><path d="M0 0 L10 5 L0 10 z" fill="currentColor"/></marker>
    </defs>
    <text class="sub" x="0" y="-6">the name you typed</text>
    <text class="sub" x="800" y="-6">where it ends up</text>

    <rect class="box b-edge" x="0" y="20" width="300" height="90" rx="6"/>
    <text class="lbl" x="150" y="62" text-anchor="middle">app.yourapp.com</text>
    <text class="sub" x="150" y="88" text-anchor="middle">a name</text>
    <path class="wire" d="M300 65 H796" marker-end="url(#a9)"/>
    <text class="arrow-label" x="548" y="52" text-anchor="middle">A record: name → address</text>
    <rect class="box b-compute" x="800" y="20" width="336" height="90" rx="6"/>
    <text class="lbl" x="968" y="62" text-anchor="middle">203.0.113.10</text>
    <text class="sub" x="968" y="88" text-anchor="middle">your host · stack 3</text>

    <rect class="box b-edge" x="0" y="190" width="300" height="90" rx="6"/>
    <text class="lbl" x="150" y="232" text-anchor="middle">www.yourapp.com</text>
    <text class="sub" x="150" y="258" text-anchor="middle">a name</text>
    <path class="wire" d="M300 235 H376" marker-end="url(#a9)"/>
    <text class="arrow-label" x="338" y="222" text-anchor="middle">CNAME</text>
    <rect class="box b-edge" x="380" y="190" width="340" height="90" rx="6"/>
    <text class="lbl" x="550" y="232" text-anchor="middle">d111abcdef8.cloudfront.net</text>
    <text class="sub" x="550" y="258" text-anchor="middle">another name: look it up again</text>
    <path class="wire" d="M720 235 H796" marker-end="url(#a9)"/>
    <text class="arrow-label" x="758" y="222" text-anchor="middle">A</text>
    <rect class="box b-edge" x="800" y="190" width="336" height="90" rx="6"/>
    <text class="lbl" x="968" y="232" text-anchor="middle">198.51.100.7</text>
    <text class="sub" x="968" y="258" text-anchor="middle">a CloudFront edge · stacks 1, 4</text>
  </svg>
  <figcaption>An A record points a name at an address. A CNAME points a name at another name, and the lookup starts over. Either way the answer carries a TTL saying how long it may be cached.</figcaption>
</figure>

### notes

About 60 seconds. A registrar gives you the name; records at the DNS host point it somewhere. A maps a name to IPv4, AAAA to IPv6. A CNAME points at another name, which is useful when the CDN's addresses change. At the bare domain, use the DNS provider's supported alias mechanism instead of a CNAME. TTL controls how long an answer may be cached.
The diagram uses documentation addresses, not real hosts. Skip the live dig here so this section stays at two minutes.

## 43. Which record, for which stack
section: The front door
eyebrow: The front door

<table>
  <thead><tr><th>Stack</th><th>Points at</th><th>Record</th><th>The catch</th></tr></thead>
  <tbody>
    <tr><td>Static site</td><td><code>&lt;id&gt;.cloudfront.net</code></td><td>CNAME, or alias at the apex</td><td>The distribution must list your name and hold a certificate for it. Ours has neither.</td></tr>
    <tr><td>Function API</td><td>a function URL</td><td>none directly</td><td>AWS lists custom domain names under API Gateway, not function URLs. Or put CloudFront in front.</td></tr>
    <tr><td>Server app</td><td>the host's IP address</td><td>A</td><td>Kamal can get an HTTPS certificate for you, once the name points at the host.</td></tr>
    <tr><td>Full-stack</td><td><code>&lt;id&gt;.cloudfront.net</code></td><td>CNAME, or alias at the apex</td><td>Same as the static site: stack 1's shape, stack 2's server.</td></tr>
  </tbody>
</table>
<p class="small" style="margin-top:18px">Custom domains are not configured in these demos. In production, add the DNS records and the endpoint's domain and certificate configuration.</p>

### notes

About 60 seconds. CloudFront needs the alternate domain name and a matching certificate as well as a DNS record. The bare Lambda function URL has no custom-domain feature; add API Gateway or a front door such as CloudFront. For the server app, point an A record at the host and configure Kamal's proxy to obtain a certificate. Our demo stacks do not configure custom domains, so this table describes the production follow-up.
Now the app has code, infrastructure, and an address. The next problem begins when two stacks need to share some of that infrastructure.

## 44. Two apps, one private connection
section: When stacks share
eyebrow: The setup · what needs to talk to what

<figure>
  <svg viewBox="0 0 1136 340" role="img" aria-label="The portal and pipeline are managed by separate Terraform states and run in separate private networks. The pipeline application writes processed results to Postgres. The portal web application reads those results through a VPC peering connection between the networks.">
    <defs>
      <marker id="shared-apps-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto-start-reverse"><path d="M0 0 L10 5 L0 10 z" fill="currentColor"/></marker>
    </defs>
    <text class="lbl" x="0" y="24">Portal stack · its own state</text>
    <text class="lbl" x="756" y="24">Pipeline stack · its own state</text>

    <rect class="box b-network" x="0" y="44" width="380" height="270" rx="6"/>
    <text class="sub" x="20" y="78">Portal VPC · private network</text>
    <rect class="box b-compute" x="30" y="150" width="320" height="100" rx="6"/>
    <text class="lbl" x="190" y="192" text-anchor="middle">Portal web app</text>
    <text class="sub" x="190" y="220" text-anchor="middle">reads the processed results</text>

    <rect class="box b-network" x="756" y="44" width="380" height="270" rx="6"/>
    <text class="sub" x="776" y="78">Pipeline VPC · private network</text>
    <rect class="box b-compute" x="786" y="98" width="320" height="76" rx="6"/>
    <text class="lbl" x="946" y="143" text-anchor="middle">Data-processing app</text>
    <path class="wire" d="M946 174 V218" marker-end="url(#shared-apps-arrow)"/>
    <text class="arrow-label" x="962" y="204">writes results</text>
    <rect class="box b-data" x="786" y="222" width="320" height="70" rx="6"/>
    <text class="lbl" x="946" y="265" text-anchor="middle">Postgres database</text>

    <path class="wire" d="M350 200 H436" marker-end="url(#shared-apps-arrow)"/>
    <rect class="box b-network" x="440" y="150" width="256" height="100" rx="6"/>
    <text class="lbl" x="568" y="192" text-anchor="middle">VPC peering</text>
    <text class="sub" x="568" y="220" text-anchor="middle">connects the networks</text>
    <path class="wire" d="M696 200 H730 V257 H782" marker-end="url(#shared-apps-arrow)"/>
  </svg>
  <figcaption>The portal needs the pipeline's data. Their private networks need a connection before the portal can read it.</figcaption>
</figure>
<p class="big" style="margin-top:20px">Who creates that connection, and what must exist first?</p>

### notes

<p>About 45 seconds, within the ownership section's existing seven-minute budget. Define the names before showing any IDs: the pipeline processes data and stores results in Postgres; the portal is the web application that needs to read those results. Each stack has its own Terraform state, which records the resources it manages.</p>
<p>The arrows here show the intended data access, not Terraform's creation order. VPC peering connects the private networks; routes and security rules also need to allow the database connection. This is a simplified production shape, not a new live demo.</p>
<p>Transition: somebody has to create the connection using both network IDs. The next slide shows what happens when the two configurations assume the other one has already done its part.</p>

## 45. Which stack owns the thing both need?
section: When stacks share
eyebrow: When stacks share things

<div class="cols">
<pre><span class="c"># pipeline stack</span>
peer_vpc_id = <span class="hl"><span class="s">"vpc-0aaaaaaaaaaaaaaaa"</span></span>
<span class="c"># owned by the portal's state</span>

<span class="c"># portal stack</span>
vpc_peering_connection_id = <span class="hl"><span class="s">"pcx-0bbbbbbbbbbbbbbbb"</span></span>
<span class="c"># owned by the pipeline's state</span></pre>
  <ul class="points tight">
    <li>Each stack hardcodes an ID the <em>other</em> state file owns.</li>
    <li>Apply either first: the other ID doesn't exist yet.</li>
    <li>The config can only describe infrastructure that already exists. It can't create it.</li>
  </ul>
</div>

### notes

<p>Sanitized from a real pair of production repos. Let the room find the bug before you say it.</p>
<p>Refer back to the diagram: the pipeline's peering request needs the portal's VPC ID; the portal's acceptance needs the pipeline's connection ID. Each configuration pastes an ID created by the other state. Ask which complete stack could be applied first in an empty environment.</p>
<p>Explain the change of example before running it: the production story used VPC peering, which Floci does not support. The local demo recreates the same cross-state hardcoded-ID failure with a security group referring to the other stack's VPC. We are testing ownership and rebuildability, not peering traffic.</p>

## 46. A bad failure, a good failure, a fix
section: When stacks share
eyebrow: When stacks share things

<div class="cols-3">
  <div>
    <h3><code>make broken</code></h3>
    <p class="small">Fails at <b>apply</b>, after creating the VPC and subnets.</p>
    <pre style="margin-top:14px;font-size:15px">InvalidVpcID.NotFound
Terraform leaves the
stack half-built.</pre>
  </div>
  <div>
    <h3><code>make order</code></h3>
    <p class="small">Out of order, but looked up by tag: fails at <b>plan</b>, creates nothing.</p>
    <pre style="margin-top:14px;font-size:15px">no matching EC2 VPC
found
with data.aws_vpc…</pre>
  </div>
  <div>
    <h3><code>make fixed</code></h3>
    <p class="small">A third <code>network/</code> layer owns both VPCs. App stacks find it by tag.</p>
    <pre style="margin-top:14px;font-size:15px">network → pipeline
network → portal
<span class="ink-plus">all three converge</span></pre>
  </div>
</div>
<div class="fill">
  <p class="big">Shared infrastructure needs one clear owner.</p>
</div>

### notes

<p>The contrast between the first two is the teaching point: a half-built apply versus a clean refusal that names what's missing.</p>
<p>Writing infrastructure in TypeScript still requires clear ownership and dependency direction. Pulumi StackReference and CDK/CloudFormation imports express dependencies; they do not make circular ownership workable.</p>
<p>Run broken, then order, then fixed. The network layer must not already be applied when order runs; check that before the talk. Spend the saved time explaining which state owns each resource and why the dependencies now point one way. A shared resource can belong to a producer stack with explicit consumers; this demo uses a separate network layer because it owns the infrastructure shared by both apps.</p>

## 47. The repo
section: Close
eyebrow: Run it yourself

<p class="big"><a href="https://github.com/raysapida/terraform_demo" style="color:var(--edge);text-underline-offset:0.15em">https://github.com/raysapida/terraform_demo</a></p>
<div class="cols">
<div class="term"><span class="p">$</span> docker compose pull
<span class="p">$</span> make up
<span class="p">$</span> make preflight
<span class="p">$</span> make site
<span class="p">$</span> make rails
<span class="p">$</span> make lambda
<span class="p">$</span> make tanstack</div>
  <div class="callout">
    <p class="label">Needs</p>
    <p>Docker with Compose v2, Terraform ≥ 1.5, make and curl. AWS CLI for the static-site demo; Ruby 4.0.5 and Bundler for Rails. Node is optional. No AWS account and no credentials.</p>
  </div>
</div>

### notes

<p>Leave https://github.com/raysapida/terraform_demo on screen for questions. The opening follow-along slide also has a QR code for the same repository.</p>
<p>Further watching: Better Stack, "This Tool Runs Real AWS Services on Your Laptop For Free (Floci)" — https://youtu.be/7s462S-qRY4 ; AwesomeFOSS, "Floci: The Drop-In LocalStack Replacement That Stays Free Forever" — https://youtu.be/brHYpf4yKKI .</p>
