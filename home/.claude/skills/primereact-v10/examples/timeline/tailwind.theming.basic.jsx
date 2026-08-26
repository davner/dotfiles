const Tailwind = {
    timeline: {
        root: ({ props }) => ({
            className: classNames('flex grow', {
                'flex-col': props.layout === 'vertical',
                'flex-row flex-1': props.layout === 'horizontal'
            })
        }),
        event: ({ props, context }) => ({
            className: classNames('flex relative min-h-[70px]', {
                'flex-row-reverse': props.align === 'right' || (props.layout === 'vertical' && props.align === 'alternate' && context.index % 2 === 1),
                'flex-col flex-1': props.layout === 'horizontal',
                'flex-col-reverse ': props.align === 'bottom' || (props.layout === 'horizontal' && props.align === 'alternate' && context.index % 2 === 1)
            })
        }),
        opposite: ({ props, context }) => ({
            className: classNames(
                'flex-1',
                {
                    'px-4': props.layout === 'vertical',
                    'py-4': props.layout === 'horizontal'
                },
                {
                    'text-right': props.align === 'left' || (props.layout === 'vertical' && props.align === 'alternate' && context.index % 2 === 0),
                    'text-left': props.align === 'right' || (props.layout === 'vertical' && props.align === 'alternate' && context.index % 2 === 1)
                }
            )
        }),
        separator: ({ props }) => ({
            className: classNames('flex items-center flex-initial', {
                'flex-col': props.layout === 'vertical',
                'flex-row': props.layout === 'horizontal'
            })
        }),
        marker: 'flex self-baseline w-4 h-4 rounded-full border-2 border-blue-500 bg-white dark:border-blue-300 dark:bg-blue-900/40',
        connector: ({ props }) => ({
            className: classNames('grow bg-gray-300 dark:bg-blue-900/40', {
                'w-[2px]': props.layout === 'vertical',
                'w-full h-[2px]': props.layout === 'horizontal'
            })
        }),
        content: ({ props, context }) => ({
            className: classNames(
                'flex-1',
                {
                    'px-4': props.layout === 'vertical',
                    'py-4': props.layout === 'horizontal'
                },
                {
                    'text-left': props.align === 'left' || (props.layout === 'vertical' && props.align === 'alternate' && context.index % 2 === 0),
                    'text-right': props.align === 'right' || (props.layout === 'vertical' && props.align === 'alternate' && context.index % 2 === 1)
                },
                {
                    'min-h-0': props.layout === 'vertical' && context.index === context.count,
                    'grow-0': props.layout === 'horizontal' && context.index === context.count
                }
            )
        })
    }
}
