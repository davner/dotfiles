const Tailwind = {          
    splitter: {
        root: ({ context }) => ({
            className: classNames('bg-white dark:bg-gray-900 rounded-lg text-gray-700 dark:text-white/80', {
                'border border-solid border-gray-300 dark:border-blue-900/40': !context.nested
            })
        }),
        splitterpanel: {
            root: 'flex grow'
        },
        gutter: ({ props }) => ({
            className: classNames('flex items-center justify-center shrink-0', 'transition-all duration-200 bg-gray-100 dark:bg-gray-800', {
                'cursor-col-resize': props.layout == 'horizontal',
                'cursor-row-resize': props.layout !== 'horizontal'
            })
        }),
        gutterhandler: ({ props }) => ({
            className: classNames('bg-gray-300 dark:bg-gray-600 transition-all duration-200', {
                'h-7': props.layout == 'horizontal',
                'w-7 h-2': props.layout !== 'horizontal'
            })
        })
    }
}
