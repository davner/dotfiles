const Tailwind = {
    inputotp: {
        root: { className: 'flex items-center gap-2' },
        input: {
            root: {
                className: classNames(
                    'box-border text-center w-10 h-11 p-3 text-slate-900 border border-gray-300 rounded-lg transition-all duration-200',
                    'hover:border-cyan-500',
                    'focus:border-cyan-500 focus:shadow-[0_0_0_0.2rem_#a5f3fc] focus:outline-0 focus:outline-offset-0'
                )
            }
        }
    }
}
