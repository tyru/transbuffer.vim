TransBuffer.vim
===============

Move buffers across multiple instances of Vim like modern browser(Google Chrome, Firefox)'s tab.


Introduction
===============

Two vim instances are running.

	---------       ---------
	| GVIM1 |       | GVIM2 |
	---------       ---------

and GVIM1 is editing `hello.txt`.

The next two commands will move
hello.txt buffer to GVIM2. (and GVIM1 buffer is closed)

```viml
	" Execute this command on GVIM2.
	:TransGetBuffer GVIM1 hello.txt
```

or

```viml
	" Execute this command on GVIM1.
	" (you can omit "hello.txt" argument
	" if current buffer is "hello.txt")
	:TransPutBuffer GVIM2 hello.txt
```

You can complete arguments by pressing `wildchar`.


If you want to open a current buffer on a new Vim instance:

```viml
	:TransPutBuffer +NEWVIM
```

will run a new Vim instance whose `v:servername` is "NEWVIM".


License
===============
NEW BSD


Author
===============
tyru &lt;tyru.exe@gmail.com&gt;
