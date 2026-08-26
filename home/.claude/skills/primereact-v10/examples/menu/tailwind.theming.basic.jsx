export const TRANSITIONS = {
    overlay: {
        timeout: 150,
        classNames: {
            enter: 'opacity-0 scale-75',
            enterActive: 'opacity-100 !scale-100 transition-transform transition-opacity duration-150 ease-in',
            exit: 'opacity-100',
            exitActive: '!opacity-0 transition-opacity duration-150 ease-linear'
        }
    }
};

const Tailwind = {
    menu: {
        root: 'py-1 bg-white dark:bg-gray-900 text-gray-700 dark:text-white/80 border border-gray-300 dark:border-blue-900/40 rounded-md w-48',
        menu: {
            className: classNames('m-0 p-0 list-none', 'outline-none')
        },
        content: ({ state }) => ({
            className: classNames(
                'text-gray-700 dark:text-white/80 transition-shadow duration-200 rounded-none',
                'hover:text-gray-700 dark:hover:text-white/80 hover:bg-gray-200 dark:hover:bg-gray-800/80', // Hover
                {
                    'bg-gray-300 text-gray-700 dark:text-white/80 dark:bg-gray-800/90': state.focused
                }
            )
        }),
        action: {
            className: classNames('text-gray-700 dark:text-white/80 py-3 px-5 select-none', 'cursor-pointer flex items-center no-underline overflow-hidden relative')
        },
        menuitem: {
            className: classNames('hover:bg-gray-200')
        },
        icon: 'text-gray-600 dark:text-white/70 mr-2',
        submenuheader: {
            className: classNames('m-0 p-3 text-gray-700 dark:text-white/80 bg-white dark:bg-gray-900 font-bold rounded-tl-none rounded-tr-none')
        },
        separator: 'border-t border-gray-300 dark:border-blue-900/40 my-1',
        transition: TRANSITIONS.overlay
    }
}
