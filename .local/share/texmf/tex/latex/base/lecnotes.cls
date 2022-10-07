% Identification
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{lecnotes}[2021/10/26 A LaTeX class to write lecture notes]

% Initialize class options
\def\lecnotes@classoptions{%
	oneside,%
	letterpaper,%
	12pt,%
}

% Defining key-value options for the class
\RequirePackage{pgfopts}
\pgfkeys{
	/ltxanswer/.cd,
	% unknown keys are assumed to be options to be passed to the class
	.unknown/.code={%
			\edef\lecnotes@classoptions{\lecnotes@classoptions,\pgfkeyscurrentname}%
		},
}
\ProcessPgfOptions*

\LoadClass[\lecnotes@classoptions]{memreport}

% Implement new commands that can be used within the first argument of
% ifthen's \ifthenelse to test whether a string is void or not, if a command is
% defined or equivalent to another.
\RequirePackage{xifthen}

% \lecture starts a new lecture (les in dutch)
%
% Usage:
% \lecture{1}{di 12 feb 2019 16:00}{Inleiding}
%
% This adds a section heading with the number / title of the lecture and a
% margin paragraph with the date.

% I use \dateparts here to hide the year (2019). This way, I can easily parse
% the date of each lecture unambiguously while still having a human-friendly
% short format printed to the pdf.
\def\testdateparts#1{\dateparts#1\relax}
\def\dateparts#1 #2 #3 #4 #5\relax{
	\marginpar{\small\textsf{\mbox{#1 #2 #3 #5}}}
}

\def\@lecture{}%
\newcommand{\lecture}[3]{
	\ifthenelse{\isempty{#3}}{%
		\def\@lecture{Lecture #1}%
	}{%
		\def\@lecture{Lecture #1: #3}%
	}%
	\chapter{\@lecture}
	\marginpar{\small\textsf{\mbox{#2}}}
}

\RequirePackage{fancyhdr}

\pagestyle{fancy}
% LE: left even
% RO: right odd
% CE, CO: center even, center odd
% My name for when I print my lecture notes to use for an open book exam.
% \fancyhead[LE,RO]{Gilles Castel}

\fancyhead[RO,LE]{\@lecture} % Right odd,	 Left even
\fancyhead[RE,LO]{}					 % Right even, Left odd
\fancyfoot[RO,LE]{\thepage}	 % Right odd,	 Left even
\fancyfoot[RE,LO]{}					 % Right even, Left odd
\fancyfoot[C]{\leftmark}		 % Center

% Define commands to input a file from another directory, allowing that file to
% find its own inputs (using \input, \includegraphics etc.) in that directory.
\RequirePackage{import}
% % Simplifies the insertion of external multi-page PDF or PS documents.
% \RequirePackage{pdfpages}
% Shows, how a separate color stack can be used for transparency, a property
% besides color.
\RequirePackage{transparent}

\newcommand{\incfig}[1]{%
	\def\svgwidth{\columnwidth}
	\import{./img/}{#1.pdf_tex}
}
