const TRANSITIONS = {
    overlay: {
        enterFromClass: 'opacity-0 scale-75',
        enterActiveClass: 'transition-transform transition-opacity duration-150 ease-in',
        leaveActiveClass: 'transition-opacity duration-150 ease-linear',
        leaveToClass: 'opacity-0'
    }
};        

const Tailwind = {
    mention: {
        root: 'relative',
        panel: 'max-h-[200px] overflow-auto bg-white dark:bg-gray-900 text-gray-700 dark:text-white/80 border-0 rounded-md shadow-lg',
        items: 'py-3 list-none m-0',
        item: 'cursor-pointer font-normal overflow-hidden relative whitespace-nowrap m-0 p-3 border-0 transition-shadow duration-200 rounded-none dark:text-white/80 dark:hover:bg-gray-800 hover:text-gray-700 hover:bg-gray-200',
        transition: TRANSITIONS.overlay
    }
}
