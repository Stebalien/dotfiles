" $Id: syslog.vim,v 1.1 2002/09/17 16:10:00 rhiestan Exp $
" Vim syntax file
" Language:	syslog log file
" Maintainer:	Bob Hiestand <bob@hiestandfamily.org>
" Last Change:	$Date: 2002/09/17 16:10:00 $
" Remark: Add some color to log files produced by sysklogd.

if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

syn match	syslogText	/.*$/
syn match	syslogFacility	/.\{-1,}:/	nextgroup=syslogText skipwhite
syn match	syslogHost	/\S\+/	nextgroup=syslogFacility,syslogText skipwhite
syn match	syslogDate	/^.\{-}\d\d:\d\d:\d\d/	nextgroup=syslogHost skipwhite

if !exists("did_syslog_syntax_inits")
  let did_syslog_syntax_inits = 1
  hi link syslogDate 	Comment
  hi link syslogHost	Type
  hi link syslogFacility	Statement
  hi link syslogText 	String
endif

let b:current_syntax="syslog"
