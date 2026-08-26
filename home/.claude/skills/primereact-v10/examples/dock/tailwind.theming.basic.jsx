const Tailwind = {
    dock: {
        root: ({ props }) => ({
            className: classNames('absolute z-1 flex justify-center items-center pointer-events-none', {
                'left-0 bottom-0 w-full': props.position == 'bottom',
                'left-0 top-0 w-full': props.position == 'top',
                'left-0 top-0 h-full': props.position == 'left',
                'right-0 top-0 h-full': props.position == 'right'
            })
        }),
        container: {
            className: classNames('flex pointer-events-auto', 'bg-white/10 border-white/20 p-2 border rounded-md')
        },
        menu: ({ props }) => ({
            className: classNames('m-0 p-0 list-none flex items-center justify-center', 'outline-none', {
                'flex-col': props.position == 'left' || props.position == 'right'
            })
        }),
        menuitem: ({ props, context, state }) => ({
            className: classNames(
                'p-2 rounded-md',
                'transition-all duration-200 ease-cubic-bezier-will-change-transform transform ',
                {
                    'origin-bottom hover:mx-6': props.position == 'bottom',
                    'origin-top hover:mx-6': props.position == 'top',
                    'origin-left hover:my-6': props.position == 'left',
                    'origin-right hover:my-6': props.position == 'right'
                },
                {
                    'hover:scale-150': state.currentIndex === context.index,
                    'scale-125': state.currentIndex - 1 === context.index || state.currentIndex + 1 === context.index,
                    'scale-110': state.currentIndex - 2 === context.index || state.currentIndex + 2 === context.index
                }
            )
        }),
        action: {
            className: classNames('flex flex-col items-center justify-center relative overflow-hidden cursor-default', 'w-16 h-16')
        }
    }
}
