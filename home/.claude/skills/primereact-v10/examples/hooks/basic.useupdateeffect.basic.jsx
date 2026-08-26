const toast = useRef(null);
const [value, setValue] = useState('');

useUpdateEffect(() => {
    toast.current.show({ severity: 'info', summary: 'Updated' });
}, [value]);
