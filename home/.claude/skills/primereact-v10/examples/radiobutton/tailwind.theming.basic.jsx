const Tailwind = {
    radiobutton: {
        root: {
            className: classNames('relative inline-flex cursor-pointer select-none align-bottom', 'w-6 h-6')
        },
        input: {
              className: classNames(
                    'absolute appearance-none top-0 left-0 size-full p-0 m-0 opacity-0 z-10 outline-none cursor-pointer'
              ),
        },
        box: ({ props }) => ({
            className: classNames(
                'flex justify-center items-center',
                'border-2 w-6 h-6 text-gray-700 rounded-full transition duration-200 ease-in-out',
                {
                    'border-gray-300 bg-white dark:border-blue-900/40 dark:bg-gray-900 dark:text-white/80': !props.checked,
                    'border-blue-500 bg-blue-500 dark:border-blue-400 dark:bg-blue-400': props.checked
                },
                {
                    'hover:border-blue-500 dark:hover:border-blue-400 focus:outline-none focus:outline-offset-0 focus:shadow-[0_0_0_0.2rem_rgba(191,219,254,1)] dark:focus:shadow-[inset_0_0_0_0.2rem_rgba(147,197,253,0.5)]': !props.disabled,
                    'cursor-default opacity-60': props.disabled
                }
            )
        }),
        icon: ({ props }) => ({
            className: classNames('transform rounded-full', 'block w-3 h-3 transition duration-200 bg-white dark:bg-gray-900', {
                'backface-hidden scale-10 invisible': !props.checked,
                'transform scale-100 visible': props.checked
            })
        })
    }
}
