{categories.map((category) => {
    return (
        <div key={category.key} className="flex align-items-center">
            <RadioButton inputId={category.key} name="category" value={category} onChange={(e) => setSelectedCategory(e.value)} checked={selectedCategory.key === category.key} />
            <label htmlFor={category.key} className="ml-2">{category.name}</label>
        </div>
    );
})}
