const Tailwind = {
    iconfield: {
        root: {
            className: classNames('relative')
        }
    },
    inputicon: {
        root: ({ context }) => ({
            className: classNames('absolute top-1/2 -mt-2', {
                'left-2': context.iconPosition === 'left',
                'right-2': context.iconPosition === 'right'
            })
        })
    },
    // For each input wrapped with IconField you will need to add styling.
    //  The following is an example for InputText
    inputtext: {
        root: ({ props, context }) => ({
            className: classNames(
                // Extend the root stylings with the following:
                {
                    'pl-8': context.iconPosition === 'left',
                    'pr-8': props.iconPosition === 'right'
                }
            )
        })
    },
}
