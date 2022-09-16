% Identification
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{ltxanswer}[2021/09/10 A LaTeX class to write answers to math questions on assignments]

% Toolbox of programming tools geared primarily towards LaTeX class and package
% authors.
\RequirePackage{etoolbox}

% Initialize class options
\def\ltxanswer@classoptions{%
  answers,%
}

% Defining key-value options for the class
\RequirePackage{pgfopts}
\pgfkeys{
  /ltxanswer/.cd,
  coursecode/.store in = \ltxans@coursecode,
  coursecode = \#\#\#\# \#\#\#,
  assignmentname/.store in = \ltxans@assignmentname,
  assignmentname = Assignment \#,
  studentnumber/.store in = \ltxans@studentnumber,
  name/.store in = \ltxans@name,
  solutiontitle/.store in = \ltxans@solutiontitle,
  solutiontitle = Answer,
  date/.store in = \ltxans@date,
  date = \today,
  swappartlabels/.is choice,
  swappartlabels/.code = {
      \newcommand{\ltxans@setupswap}{
        \renewcommand{\thepartno}{\roman{partno}}
        \renewcommand{\thesubpart}{\alph{subpart}}
        \renewcommand{\subpartlabel}{(\thesubpart)}
      }
    },
  % unknown keys are assumed to be options to be passed to the class
  .unknown/.code={
      \edef\ltxanswer@classoptions{\ltxanswer@classoptions,\pgfkeyscurrentname}
    }
}
\ProcessPgfOptions*

% Using the exam class as a base since it already provides environments for
% questions and solutions!
\LoadClass[\ltxanswer@classoptions]{exam}

% Customizing the question numbers.
\renewcommand{\subpartlabel}{(\thesubpart)}
\AtBeginDocument{
  \ifdef{\ltxans@setupswap}{
    \ltxans@setupswap
  }{}
}

% Provides an interface for selecting code depending on the options `draft' and
% `final'.
\RequirePackage{ifdraft}

% Allows a convenient redaction/censor capability to be employed, for those
% who need to protect restricted information, as well as for those who are
% forced to work in a more inefficient environment when dealing with restricted
% information.
\RequirePackage{censor}

\ifoptionfinal{
  \StopCensoring
}{}

\pagestyle{headandfoot}

% Header
\extraheadheight{0.2in}
\newcommand{\ltxans@headerlinebreak}{\\\vspace{0.2in}}
\header{%
  \ltxans@coursecode
  \ifdef{\ltxans@studentnumber}{%
    \ltxans@headerlinebreak%
    Student Number: \underline{\censor{\ltxans@studentnumber}}%
  }{
    \ifdef{\ltxans@name}{%
      \ltxans@headerlinebreak%
    }{}%
  }%
}{%
  \ltxans@assignmentname
  \ifdef{\ltxans@studentnumber}{%
    \ltxans@headerlinebreak%
  }{
    \ifdef{\ltxans@name}{%
      \ltxans@headerlinebreak%
    }{}%
  }%
}{%
  \ltxans@date%
  \ifdef{\ltxans@name}{%
    \ltxans@headerlinebreak%
    Name: \underline{\ltxans@name}%
  }{
    \ifdef{\ltxans@studentnumber}{%
      \ltxans@headerlinebreak%
    }{}%
  }%
}

% Footer
\extrafootheight{-0.125in}
\footer{}{Page \thepage\ of \numpages}{}

\renewcommand{\questionshook}{
  \setlength{\leftmargin}{0pt}
  % \setlength{\labelwidth}{-\labelsep}%
}

\renewcommand{\partshook}{
  \setlength{\leftmargin}{0pt}
}

\renewcommand{\subpartshook}{
  \setlength{\leftmargin}{0pt}
}

% Solutions
\unframedsolutions
\renewcommand{\solutiontitle}{
  \noindent\textbf{\ltxans@solutiontitle:}\par\noindent
}

% Custom figure environment inside of answers.
% https://tex.stackexchange.com/a/26522/204377
\newenvironment{answerfigure}{%
  \hfill\allowbreak%
  \begin{minipage}[t]{\linewidth}%
    \centering
    % The default values in the article document class with the 10pt option are:
    \vspace{12.0pt plus 2.0pt minus 4.0pt}
    \captionsetup{type=figure}
    }{%
    \vspace{12.0pt plus 2.0pt minus 4.0pt}
  \end{minipage}%
}
