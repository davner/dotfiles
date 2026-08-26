const Tailwind = {
    knob: {
        root: ({ props }) => ({
            className: classNames('focus:outline-none focus:outline-offset-0 focus:shadow-0', {
                'opacity-60 select-none pointer-events-none cursor-default': props.disabled
            })
        }),
        range: 'stroke-current transition duration-100 ease-in stroke-gray-200 dark:stroke-gray-700 fill-none',
        value: 'animate-dash-frame  stroke-blue-500 fill-none',
        label: 'text-center text-xl'
    }
}
