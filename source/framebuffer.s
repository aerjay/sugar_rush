	.section .text

.globl InitFrameBuffer

// Initialize the FrameBuffer using the FrameBufferInit structure

InitFrameBuffer:

	mbox	.req	r2 					// loads the address of the mailbox interface
	ldr		mbox, =0x2000B880

	fbinit	.req	r3					// load the address of the framebuffer init structure
	ldr		fbinit,	=FrameBufferInit

mBoxFullLoop$:

	ldr		r0, [mbox, #0x18]			// load the value of the mailbox status register

	tst		r0, #0x80000000 			// loop while bit 31 (Full) is set, until mailbox is full
	bne		mBoxFullLoop$

	add		r0, fbinit, #0x40000000			// add 0x40000000 to address of framebuffer init struct, store in r0

	orr		r0, #0b0001 				// or with the framebuffer channel (1)
	str		r0, [mbox, #0x20] 			// write this value to the mailbox write register

mBoxEmptyLoop$:

	ldr		r0, [mbox, #0x18]			// load the value of the mailbox status register

	tst		r0, #0x40000000 			// loop while bit 30 (Empty) is set, until mailbox is empty
	bne		mBoxEmptyLoop$

								// read the response from the mailbox read register
	ldr		r0, [mbox, #0x00]

								// and-mask out the channel information (lowest 4 bits)
	and		r1, r0, #0xF

								// test if this message is for the framebuffer channel (1)
	teq		r1, #0b0001

								// if not, we need to read another message from the mailbox
	bne		mBoxEmptyLoop$
								// isolate the high 28 bits of the message
	bic		r1, r0, #0xF

								// test if the high 28 bits of the message are 0 (ie: success)
	teq		r1, #0
								// return 0 if high 28 bits of message are not 0
	movne		r0, #0

	bxne		lr					// return

pointerWaitLoop$:

								// load the value of the pointer from the framebuffer init struct
	ldr		r0, [fbinit, #0x20]
								// loop while the pointer is 0
	teq		r0, #0
	beq		pointerWaitLoop$

	.unreq		mbox
	.unreq		fbinit

	ldr 		r3, =FrameBufferPointer
	str		r0, [r3]
								// return the pointer value to indicate success
	bx		lr

	.section .data

.align 4
FrameBufferInit:
	.int	1024			// X Resolution (width)
	.int	768			// Y Resolution (height)
	.int	1024			// Virtual Width
	.int	768			// Virtual Height
	.int	0			// Pitch (Set by GPU)
	.int	16			// Depth (bits per pixel)
	.int	0			// Virtual X Offset
	.int	0			// Virtual Y Offset
	.int	0			// Pointer to FrameBuffer (Set by GPU)
	.int	0			// Size of FrameBuffer (Set by GPU)

.align 4
.globl FrameBufferPointer
FrameBufferPointer:
	.int	0


