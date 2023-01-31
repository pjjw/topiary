; Configuration
(#language! bash)

; NOTE There is (currently) no support for line continuations. As such,
; any which are encountered by Topiary will be forcibly collapsed on to
; a single line. (See Issue #172)

; Don't modify string literals, heredocs, comments, atomic "words" or
; variable expansions (simple or otherwise)
; FIXME The first line of heredocs are affected by the indent level
[
  (comment)
  (expansion)
  (heredoc_body)
  (simple_expansion)
  (string)
  (word)
] @leaf

;; Spacing

; Allow blank line before
[
  (c_style_for_statement)
  (case_item)
  (case_statement)
  (command)
  (comment)
  (compound_statement)
  (declaration_command)
  (for_statement)
  (function_definition)
  (if_statement)
  (list)
  (pipeline)
  (redirected_statement)
  (subshell)
  (variable_assignment)
  (while_statement)
] @allow_blank_line_before

; Insert a new line before multi-line syntactic blocks, regardless of
; context
[
  (c_style_for_statement)
  (case_statement)
  (for_statement)
  (function_definition)
  (if_statement)
  (while_statement)
] @prepend_hardline

; Subshells and compound statements should have a new line inserted
; before them when they are top-level constructs. Beyond that level, the
; extra spacing makes the code overly sparse. (This is also a pragmatic
; choice: as we have to avoid the exception of function definitions, the
; list of complementary contexts we'd have to enumerate queries over is
; rather large!)
(program
  [
    (compound_statement)
    (subshell)
  ] @prepend_hardline
)

; A run of "units of execution" (see Commands section, below; sans
; variables which are special) should be interposed by a new line, after
; a multi-line syntactic block or variable.
(
  [
    (c_style_for_statement)
    (case_statement)
    (declaration_command)
    (for_statement)
    (function_definition)
    (if_statement)
    (variable_assignment)
    (while_statement)
  ]
  .
  ; Commands (sans variables)
  [(command) (list) (pipeline) (subshell) (compound_statement) (redirected_statement)] @prepend_hardline
)

; A run of variable declarations and assignments should be interposed by
; a new line, after almost anything else. This makes them stand out.
(
  [
    (c_style_for_statement)
    (case_statement)
    (command)
    (compound_statement)
    (for_statement)
    (function_definition)
    (if_statement)
    (list)
    (pipeline)
    (redirected_statement)
    (subshell)
    (while_statement)
  ]
  .
  [
    (declaration_command)
    (variable_assignment)
  ] @prepend_hardline
)

; Append a space to the following keywords and delimiters
[
  ";"
  "case"
  "declare"
  "do"
  "elif"
  "export"
  "for"
  "if"
  "in"
  "local"
  "readonly"
  "select"
  "then"
  "typeset"
  "until"
  "while"
] @append_space

; Prepend a space to intra-statement keywords
[
  "in"
] @prepend_space

;; Comments

; Comments come in two flavours: standalone (i.e., it's the only thing
; on a line, starting at the current indent level); and trailing (i.e.,
; following some other statement on the same line, with a space
; interposed). Bash does not have multi-line comments; they are all
; single-line.
;
; The grammar parses all comments as the (comment) node, which are
; siblings under a common parent.
;
; Formatting Rules:
;
; 1. A comment's contents must not be touched; some (namely the shebang)
;    have a syntactic purpose.
; 2. All comments must end with a new line.
; 3. Comments can be interposed by blank lines, if they exist in the
;    input (i.e., blank lines shouldn't be engineered elsewhere).
; 4. A run of standalone comments (i.e., without anything, including
;    blank lines, interposing) should be kept together.
; 5. Trailing comments should only appear after "units of execution" or
;    variable declarations/assignment. (This is despite it being
;    syntactically valid to put them elsewhere.)

; FIXME
(comment) @append_hardline

;; Compound Statements and Subshells

; Compound statements and subshells are formatted in exactly the same
; way. In a multi-line context, their opening parenthesis triggers a new
; line and the start of an indent block; the closing parenthesis
; finishes that block. In a single-line context, spacing is used instead
; of new lines (NOTE that this is a syntactic requirement of compound
; statements, but not of subshells).
;
; NOTE Despite being isomorphic, the queries for compound statements and
; subshells are _not_ generalised, to ensure parentheses balance.

(compound_statement
  .
  "{" @append_spaced_softline @append_indent_start
  _
  "}" @prepend_spaced_softline @prepend_indent_end
  .
)

(subshell
  .
  "(" @append_spaced_softline @append_indent_start
  _
  ")" @prepend_spaced_softline @prepend_indent_end
  .
)

;; Commands

; "Command" is an epithet for, broadly speaking, a "unit of execution".
; It is such a pervasive and general concept in Bash that we need to
; take care when considering the context. For example, the condition in
; an if statement or while loop is a command, but we don't want to
; insert a new line in these cases.
;
; In terms of the grammar, the following nodes should be considered
; "commands":
;
; * (command)
;   Simple commands (e.g., binaries, builtins, functions, etc.)
;
; * (list)
;   Command lists (i.e., "commands" sequenced by && and ||)
;
; * (pipeline)
;   Command pipelines (i.e., "commands" sequenced by | and |&)
;
; * (subshell)
;   Subshells (i.e., arbitrary code enclosed within parentheses)
;
; * (compound_statement)
;   Compound statements (i.e., arbitrary code enclosed within
;   curly-parentheses)
;
; * (redirected_statement)
;   IO redirection (NOTE These aren't semantically "units of execution"
;   in their own right, but are treated as such due to how the grammar
;   organises them as parent nodes of such units)
;
; * (variable_assignment)
;   Variable assignment (NOTE These aren't "units of execution" at all,
;   but are treated as such to isolate them from their declaration
;   context; see Variables section, below)

; We care about the line spacing of "commands" that appear in any of the
; following contexts:
;
; * Top-level statements
; * Multi-line compound statements and subshells
; * Any branch of a conditional or case statement
; * Loop bodies
; * Multi-line command substitutions
;
; We address each context individually, as there's no way to isolate the
; exceptional contexts, where no line spacing is required.
;
; When a "command" is followed by another "command" or context, it
; should be interposed by a new (soft)line, for the sake of single-line
; compound statements and subshells. (NOTE The ((foo) @bar . (foo))
; query pattern is to avoid applying @bar to trailing elements.)

(program
  [(command) (list) (pipeline) (subshell) (compound_statement) (redirected_statement) (variable_assignment)] @append_hardline
  .
  [
    ; Commands
    (command) (list) (pipeline) (subshell) (compound_statement) (redirected_statement) (variable_assignment)
    ; Contexts
    (c_style_for_statement) (case_statement) (declaration_command) (for_statement) (function_definition) (if_statement) (while_statement)
  ]
)

; NOTE Single-line compound statements are a thing; hence the softline
(compound_statement
  [(command) (list) (pipeline) (compound_statement) (subshell) (redirected_statement) (variable_assignment)] @append_empty_softline
  .
  [
    ; Commands
    (command) (list) (pipeline) (subshell) (compound_statement) (redirected_statement) (variable_assignment)
    ; Contexts
    (c_style_for_statement) (case_statement) (declaration_command) (for_statement) (function_definition) (if_statement) (while_statement)
  ]
)

; NOTE Single-line subshells are a thing; hence the softline
(subshell
  [(command) (list) (pipeline) (compound_statement) (subshell) (redirected_statement) (variable_assignment)] @append_empty_softline
  .
  [
    ; Commands
    (command) (list) (pipeline) (subshell) (compound_statement) (redirected_statement) (variable_assignment)
    ; Contexts
    (c_style_for_statement) (case_statement) (declaration_command) (for_statement) (function_definition) (if_statement) (while_statement)
  ]
)

(if_statement
  .
  _
  "then"
  [(command) (list) (pipeline) (compound_statement) (subshell) (redirected_statement) (variable_assignment)] @append_hardline
  .
  [
    ; Commands
    (command) (list) (pipeline) (subshell) (compound_statement) (redirected_statement) (variable_assignment)
    ; Contexts
    (c_style_for_statement) (case_statement) (declaration_command) (for_statement) (function_definition) (if_statement) (while_statement)
  ]
)

(elif_clause
  .
  _
  "then"
  [(command) (list) (pipeline) (compound_statement) (subshell) (redirected_statement) (variable_assignment)] @append_hardline
  .
  [
    ; Commands
    (command) (list) (pipeline) (subshell) (compound_statement) (redirected_statement) (variable_assignment)
    ; Contexts
    (c_style_for_statement) (case_statement) (declaration_command) (for_statement) (function_definition) (if_statement) (while_statement)
  ]
)

(else_clause
  .
  "else"
  [(command) (list) (pipeline) (compound_statement) (subshell) (redirected_statement) (variable_assignment)] @append_hardline
  .
  [
    ; Commands
    (command) (list) (pipeline) (subshell) (compound_statement) (redirected_statement) (variable_assignment)
    ; Contexts
    (c_style_for_statement) (case_statement) (declaration_command) (for_statement) (function_definition) (if_statement) (while_statement)
  ]
)

; NOTE Single-line case branches are a thing; hence the softline
(case_item
  .
  _
  ")"
  [(command) (list) (pipeline) (compound_statement) (subshell) (redirected_statement) (variable_assignment)] @append_empty_softline
  .
  [
    ; Commands
    (command) (list) (pipeline) (subshell) (compound_statement) (redirected_statement) (variable_assignment)
    ; Contexts
    (c_style_for_statement) (case_statement) (declaration_command) (for_statement) (function_definition) (if_statement) (while_statement)
  ]
)

(do_group
  .
  "do"
  [(command) (list) (pipeline) (compound_statement) (subshell) (redirected_statement) (variable_assignment)] @append_hardline
  .
  [
    ; Commands
    (command) (list) (pipeline) (subshell) (compound_statement) (redirected_statement) (variable_assignment)
    ; Contexts
    (c_style_for_statement) (case_statement) (declaration_command) (for_statement) (function_definition) (if_statement) (while_statement)
  ]
)

; NOTE Single-line command substitutions are a thing; hence the softline
(command_substitution
  [(command) (list) (pipeline) (compound_statement) (subshell) (redirected_statement) (variable_assignment)] @append_empty_softline
  .
  [
    ; Commands
    (command) (list) (pipeline) (subshell) (compound_statement) (redirected_statement) (variable_assignment)
    ; Contexts
    (c_style_for_statement) (case_statement) (declaration_command) (for_statement) (function_definition) (if_statement) (while_statement)
  ]
)

; Surround command list and pipeline delimiters with spaces
; NOTE The context here may be irrelevant -- i.e., these operators
; should always be surrounded by spaces -- but they're kept here,
; separately, in anticipation of line continuation support in multi-line
; contexts.
(list
  [
    "&&"
    "||"
  ] @append_space @prepend_space
)

(pipeline
  [
    "|"
    "|&"
  ] @append_space @prepend_space
)

; Prepend the asynchronous operator with a space
; NOTE If I'm not mistaken, this can interpose two "commands" -- like a
; delimiter -- but I've never seen this form in the wild
(_
  [(command) (list) (pipeline) (compound_statement) (subshell) (redirected_statement)]
  .
  "&" @prepend_space
)

; Space between command line arguments
; NOTE If we treat (command) as a leaf node, then commands are formatted
; as is and the below will be ignored. On balance, I think keeping this
; rule, rather than deferring to the input, is the better choice
; (although it's not without its problems; e.g., see Issue #172).
(command
  argument: _* @prepend_space
)

; Ensure the negation operator is surrounded by spaces
; NOTE This is a syntactic requirement
(negated_command
  .
  "!" @prepend_space @append_space
)

; Multi-line command substitutions become an indent block
(command_substitution
  .
  (_) @prepend_empty_softline @prepend_indent_start
)

(command_substitution
  ")" @prepend_empty_softline @prepend_indent_end
  .
)

;; Redirections

; Insert a space before all redirection operators, but _not_ after
(redirected_statement
  redirect: _* @prepend_space
)

; ...with the exceptions of herestrings, that are spaced
(herestring_redirect (_) @prepend_space)

; Ensure heredocs start on a new line, after their start marker, and
; there is a new line after their end marker, when followed by any named
; node. (NOTE This may need some refinement...)
; NOTE These are a syntactic requirements
(heredoc_start) @append_hardline
(
  (heredoc_body) @append_hardline
  .
  (_)
)

;; Conditionals

; New line after conditionals
[
  (if_statement)
  (elif_clause)
  (else_clause)
] @append_hardline

; New line after "then" and start indent block
[
  (if_statement)
  (elif_clause)
] "then" @append_hardline @append_indent_start

; New line after "else" and start indent block
(else_clause
  .
  "else" @append_hardline @append_indent_start
)

; Finish indent block at "fi", "else" or "elif"
(if_statement
  [
    "fi"
    (else_clause)
    (elif_clause)
  ] @prepend_indent_end @prepend_hardline
)

; Keep the "if"/"elif" and the "then" on the same line,
; inserting a spaced delimiter when necessary
; FIXME Why does the space need to be explicitly inserted?
(_
  ";"* @do_nothing
  .
  "then" @prepend_delimiter @prepend_space

  (#delimiter! ";")
)

;; Test Commands

(test_command
  .
  (unary_expression
    _ @prepend_space
  ) @append_space
)

; FIXME The binary_expression node is not being returned by Tree-Sitter
; in the context of a (test_command); it does work in other contexts
; See https://github.com/tweag/topiary/pull/155#issuecomment-1364143677
(binary_expression
   left: _ @append_space
   right: _ @prepend_space
)

;; Case Statements

; Indentation block between the "in" and the "esac"
(case_statement
  .
  "case" . _ .  "in" @append_hardline @append_indent_start
  _
  "esac" @prepend_hardline @prepend_indent_end
  .
) @append_hardline

; New (soft)line after branch, which starts an indentation block up
; until its end
(case_item
  ")" @append_spaced_softline @append_indent_start
) @append_indent_end

; Ensure case branch terminators appear on their own line, in a
; multi-line context; or, at least, push the next case branch on to a
; new line in a single-line context
; NOTE The terminator is optional in the final condition, which is why
; we deal with closing the indent block above
(case_item
  [
    ";;"
    ";;&"
    ";&"
  ] @prepend_empty_softline @append_hardline
  .
)

;; Loops

; Indentation block between the "do" and the "done"
(do_group
  .
  "do" @append_hardline @append_indent_start
  _
  "done" @prepend_hardline @prepend_indent_end
  .
) @append_hardline

; Ensure the word list is delimited by spaces in classic for loops
(for_statement
  value: _* @prepend_space
)

; Surround the loop condition with spaces in C-style for loops
(c_style_for_statement
  initializer: _ @prepend_space
  update: _ @append_space
)

; Keep the loop construct and the "do" on the same line,
; inserting a spaced delimiter when necessary
; FIXME Why does the space need to be explicitly inserted?
(_
  ";"* @do_nothing
  .
  (do_group) @prepend_delimiter @prepend_space

  (#delimiter! ";")
)

;; Function Definitions

; NOTE Much of the formatting work for function definitions is done by
; whatever already-defined queries apply to the function body (e.g.,
; (compound_statement), etc.). All we do here is ensure functions get
; a space between its name and body, a new line afterwards and deleting
; the redundant "function" keyword, if it exists in the input.

; NOTE Technically speaking, a function body can be _any_ compound. For
; example, this is valid Bash:
;
;   my_function() for x in $@; do echo $x; done
;
; However, this form is never seen in the wild and the Tree Sitter Bash
; grammar won't even parse it. It only accepts subshells, compound
; statements and test commands as function bodies.

(function_definition
  body: _ @prepend_space @append_hardline
)

(function_definition
  .
  "function" @delete
)

;; Variable Declaration, Assignment and Expansion

; NOTE It would be nice to convert (simple_expansion) nodes into
; (expansion) nodes by inserting "delimiters" in appropriate places.
; This doesn't appear to currently be possible (see Issue #187).

; NOTE Assignment only gets a new line when not part of a declaration;
; that is, all the contexts in which units of execution can appear.
; Hence the queries for this are defined above. (My kingdom for a
; negative anchor!)

; Declarations always end with a new line
(declaration_command) @append_hardline

; Multiple variables can be exported (and assigned) at once
(declaration_command
  .
  "export"
  [(variable_name) (variable_assignment)] @prepend_space
)

; Environment variables assigned to commands inline need to be spaced
(command
  (variable_assignment) @append_space
)