const Tailwind = {
    multistatecheckbox: {
        root: {
            className: classNames('cursor-pointer inline-flex relative select-none align-bottom', 'w-6 h-6')
        },
        checkbox: ({ props }) => ({
            className: classNames(
                'flex items-center justify-center',
                'border-2 w-6 h-6 rounded-lg transition-colors duration-200',
                {
                    'border-blue-500 bg-blue-500 text-white dark:border-blue-400 dark:bg-blue-400': props.value || !props.value,
                    'border-gray-300 text-gray-600 bg-white dark:border-blue-900/40 dark:bg-gray-900': props.value == null
                },
                {
                    'hover:border-blue-500 dark:hover:border-blue-400 focus:outline-none focus:outline-offset-0 focus:shadow-[0_0_0_0.2rem_rgba(191,219,254,1)] dark:focus:shadow-[inset_0_0_0_0.2rem_rgba(147,197,253,0.5)]': !props.disabled,
                    'cursor-default opacity-60': props.disabled
                }
            )
        })
    }
}
