const TRANSITIONS = {
    overlay: {
        classNames: {
            enter: 'opacity-0 scale-75',
            enterActive: 'opacity-100 !scale-100 transition-transform transition-opacity duration-150 ease-in',
            exit: 'opacity-100',
            exitActive: '!opacity-0 transition-opacity duration-150 ease-linear'
        }
    }
};

const Tailwind = {
    overlaypanel: {
        root: {
            className: classNames(
                'bg-white text-gray-700 border-0 rounded-md shadow-lg',
                'z-40 transform origin-center',
                'absolute left-0 top-0 mt-3',
                'before:absolute before:w-0 before:-top-3 before:h-0 before:border-transparent before:border-solid before:ml-6 before:border-x-[0.75rem] before:border-b-[0.75rem] before:border-t-0 before:border-b-white dark:before:border-b-gray-900',
                'dark:border dark:border-blue-900/40 dark:bg-gray-900  dark:text-white/80'
            )
        },
        closeButton: 'flex items-center justify-center overflow-hidden absolute top-0 right-0 w-6 h-6',
        content: 'p-5 items-center flex',
        transition: TRANSITIONS.overlay
    }
}
