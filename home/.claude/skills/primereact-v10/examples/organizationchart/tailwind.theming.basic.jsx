const Tailwind = {
    organizationchart: {
        table: 'mx-auto my-0 border-spacing-0 border-separate',
        cell: 'text-center align-top py-0 px-3',
        node: {
            className: classNames(
                'relative inline-block bg-white border border-gray-300 text-gray-600 p-5',
                'dark:border-blue-900/40 dark:bg-gray-900 dark:text-white/80' // Dark Mode
            )
        },
        linecell: 'text-center align-top py-0 px-3',
        linedown: {
            className: classNames(
                'mx-auto my-0 w-px h-[20px] bg-gray-300',
                'dark:bg-blue-900/40' //Dark Mode
            )
        },
        lineleft: ({ context }) => ({
            className: classNames(
                'text-center align-top py-0 px-3 rounded-none border-r border-gray-300',
                'dark:border-blue-900/40', //Dark Mode
                {
                    'border-t': context.lineTop
                }
            )
        }),
        lineright: ({ context }) => ({
            className: classNames(
                'text-center align-top py-0 px-3 rounded-none',
                'dark:border-blue-900/40', //Dark Mode
                {
                    'border-t border-gray-300': context.lineTop
                }
            )
        }),
        nodecell: 'text-center align-top py-0 px-3',
        nodetoggler: {
            className: classNames(
                'absolute bottom-[-0.75rem] left-2/4 -ml-3 w-6 h-6 bg-inherit text-inherit rounded-full z-2 cursor-pointer no-underline select-none',
                'focus:outline-none focus:outline-offset-0 focus:shadow-[0_0_0_0.2rem_rgba(191,219,254,1)] dark:focus:shadow-[0_0_0_0.2rem_rgba(147,197,253,0.5)]' // Focus styles
            )
        },
        nodetogglericon: 'relative inline-block w-4 h-4'
    }
}
