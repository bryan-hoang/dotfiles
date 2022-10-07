\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{memreport}[2021/11/14 A LaTeX class to style memoir for reports]

% Toolbox of programming tools geared primarily towards LaTeX class and package
% authors.
\RequirePackage{etoolbox}

% Initialize class options
\def\memreport@classoptions{%
	oneside,%
	letterpaper,%
	12pt,%
}

\newbool{memreport@if@endnotes}

% Defining key-value options for the class
\RequirePackage{pgfopts}
\pgfkeys{
	/memreport/.cd,
	% unknown keys are assumed to be options to be passed to the class
	.unknown/.code={
			\edef\memreport@classoptions{\memreport@classoptions,\pgfkeyscurrentname}
		},
	promotesection/.is choice,
	promotesection/.code = {
			\newcommand{\memreport@setuppromote}{
				\renewcommand{\thesection}{\arabic{section}}
				\renewcommand{\thesubsection}{\thesection.\arabic{subsection}}
				\makeatletter
				\let\l@subsection\l@section
				\let\l@section\l@chapter
				\makeatother
			}
		},
	endnotes/.is choice,
	endnotes/.code = {\booltrue{memreport@if@endnotes}},
}

\ProcessPgfOptions*

\LoadClass[\memreport@classoptions]{memoir}

\ifdef{\memreport@setuppromote}{
	\memreport@setuppromote
}{}

% Normalizing margins.
\setlrmarginsandblock{1in}{1in}{*}
\setulmarginsandblock{1in}{*}{1}
\checkandfixthelayout[nearest]

% Plain header and footer (page number centered at the bottom)
\pagestyle{plain}

% Number subsubsections and above in TOC.
\setsecnumdepth{subsubsection}
\maxtocdepth{subsubsection}

% Provide control over the typesetting of the \maketitle and \thanks commands.
\RequirePackage{titling}

% Vertically center \maketitle
\renewcommand\maketitlehooka{\null\mbox{}\vfill}
\renewcommand\maketitlehookd{\vfill\null}

% Changing the title of the table of contents section.
\RequirePackage[USenglish,UKenglish]{babel}

\addto\captionsenglish{\renewcommand*\contentsname{Table of Contents}}

% A replacement|partial or total|for the LATEX macros related with
% sections|namely titles, headers and contents.
\RequirePackage{titlesec}

% `straight' class is intended for titles in the middle of text. i.e., no page
% break before.
\titleclass{\chapter}{straight}

% Change formatting of chapter titles
\titleformat{\chapter}{\normalfont\bfseries\huge}{\thechapter}{0.75em}{}
\titlespacing*{\chapter}{0pt}{30pt}{20pt}

% Remove space before chapters and sections in TOC.
\setlength{\cftbeforechapterskip}{0pt plus 0pt}
\renewcommand*{\insertchapterspace}{}
\setlength{\cftbeforesectionskip}{0pt plus 0pt}

% region References

\providecommand{\main}{.}

% `biblatex`' will use its language sensitive quotation facilities to enclose
% certain titles in quotation marks.
\RequirePackage{csquotes}

% Change citation styles.
\notbool{memreport@if@endnotes}{
	% Provides advanced bibliographic facilities for use with LaTeX.
	\RequirePackage[
		autocite=plain,
		style=ieee,
		dateabbrev=false,
	]{biblatex}

	\AtEndDocument{%
		\printbibliography[
			title=References,
			heading=bibintoc,
		]%
	}
}{
	% New implementation of endnotes for LATEX2" since the endnotes package
	% [Lav03] has some deficiencies.
	\RequirePackage{enotez}
	% Redefinine footnote for citations
	\let\footnote=\endnote
	% Customize default style to match `endnotes`'s style more closely.
	\DeclareInstance{enotez-list}{plain}{paragraph}{
		number=\makebox[0pt][r]{\textsuperscript{#1}},
		format=\normalfont,
	}

	% Setup command for setting enotez' options.
	\setenotez{
		backref,
		list-style=plain,
		% Change the heading to use a footnoterule
		list-heading=\kern2\baselineskip\footnoterule\kern1\baselineskip,
	}

	\AtEndDocument{
		\printendnotes{}
	}

	% Provides advanced bibliographic facilities for use with LaTeX.
	\RequirePackage[
		style=ieee,
		bibstyle=ieee,
		citestyle=verbose-ibid,
		autocite=footnote,
		notetype=endonly,
		dateabbrev=false,
	]{biblatex}
}

% Formatting urls.

% Loads package url by default and defines possible url breaks for all
% alphanumerical characters and `= / . : * - ~ ' "'.
\RequirePackage{xurl}

% % Improves on `etoolbox`'s shortcomings'
% \RequirePackage{xpatch}

% % To remove (). at the beginning of references with no date.
% \xpatchbibdriver{online}
% {\printtext[parens]{\usebibmacro{date}}}
% {\iffieldundef{year}{}{\printtext[parens]{\usebibmacro{date}}}}
% {}{}

% Formatting urls in bibliography.
\DefineBibliographyStrings{english}{
	urlseen={Accessed}
}
\DeclareFieldFormat{urldate}{[\bibstring{urlseen}\space#1]}
\DefineBibliographyStrings{english}{%
	url = [Online]\adddot\addspace Available:%
}
\DeclareFieldFormat{url}{\bibstring{url}\space\url{#1}.}

% % Deciding when to print the bibliography.
% \makeatletter
% \newrobustcmd*{\nobibliography}{%
%		\@ifnextchar[%]
%		{\blx@nobibliography}
%		{\blx@nobibliography[]}}
% \def\blx@nobibliography[#1]{}
% \appto{\skip@preamble}{\let\printbibliography\nobibliography}
% \makeatother

% endregion
