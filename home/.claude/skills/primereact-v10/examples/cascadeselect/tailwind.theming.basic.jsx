const TRANSITIONS = {
    overlay: {
        timeout: 150,
        classNames: {
            enter: 'opacity-0 scale-75',
            enterActive: 'transition-transform transition-opacity duration-150 ease-in',
            exit: 'opacity-0',
            exitActive: 'transition-opacity duration-150 ease-linear'
        }
    }
};

const Tailwind = {        
    cascadeselect: {
        root: ({ props }) => ({
            className: classNames('inline-flex cursor-pointer select-none relative', 'bg-white dark:bg-gray-900 border border-gray-300 dark:border-blue-900/40 transition duration-200 ease-in-out rounded-lg', {
                'opacity-60 select-none pointer-events-none cursor-default': props.disabled
            })
        }),
        label: {
            className: classNames('block whitespace-nowrap overflow-hidden flex flex-1 w-1 text-overflow-ellipsis cursor-pointer', 'bg-transparent border-0 p-3 text-gray-700 dark:text-white/80', 'appearance-none rounded-md')
        },
        dropdownButton: {
            className: classNames('flex items-center justify-center shrink-0', 'bg-transparent text-gray-600 dark:text-white/80 w-[3rem] rounded-tr-6 rounded-br-6')
        },
        panel: { className: 'absolute py-3 bg-white dark:bg-gray-900 border-0 shadow-md' },
        list: { className: 'm-0 sm:p-0 list-none' },
        sublist: {
            className: classNames('block absolute left-full top-0', 'min-w-full z-10', 'py-3 bg-white dark:bg-gray-900 border-0 shadow-md')
        },
        item: ({ state }) => ({
            className: classNames('cursor-pointer font-normal whitespace-nowrap', 'm-0 border-0 bg-transparent transition-shadow rounded-none', {
                'text-gray-700 hover:text-gray-700 hover:bg-gray-200 dark:text-white/80 dark:hover:text-white/80 dark:hover:bg-gray-800/80': !state.selected,
                'bg-blue-50 text-blue-700 dark:bg-blue-300 dark:text-white/80': state.selected
            })
        }),
        content: {
            className: classNames('flex items-center overflow-hidden relative', 'py-3 px-5')
        },
        optionGroupIcon: { className: 'ml-auto' },
        transition: TRANSITIONS.overlay
    }
}
