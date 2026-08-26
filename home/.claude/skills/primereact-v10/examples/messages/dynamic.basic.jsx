<Button type="button" onClick={addMessages} label="Show" className="mr-2" />
<Button type="button" onClick={clearMessages} label="Clear" className="p-button-secondary" />

<Messages ref={msgs} />
