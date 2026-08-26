        <Calendar
            value={date}
            onChange={(e) => setDate(e.value)}
            appendTo={typeof window !== 'undefined' ? document.body : null}
        />
