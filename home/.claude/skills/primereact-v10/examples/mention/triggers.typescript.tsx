import React, { useState, useEffect } from "react";
import { Mention, MentionSearchEvent, MentionItemTemplateOptions } from 'primereact/mention';
import { CustomerService } from './service/CustomerService';

export default function TriggersDemo() {
    const [value, setValue] = useState<string>('');
    const [customers, setCustomers] = useState<any>([]);
    const [multipleSuggestions, setMultipleSuggestions]= useState<any>([]);
    const tagSuggestions = ['primereact', 'primefaces', 'primeng', 'primevue'];
    
    useEffect(() => {
        CustomerService.getCustomersSmall().then(data => {
            data.forEach(d => d['nickname'] = `${d.name.replace(/\s+/g, '').toLowerCase()}_${d.id}`);
            setCustomers(data);
        });
    }, [])

    const onMultipleSearch = (event: MentionSearchEvent) => {
        const trigger = event.trigger;

        if (trigger === '@') {
            //in a real application, make a request to a remote url with the query and return suggestions, for demo we filter at client side
            setTimeout(() => {
                const query = event.query;
                let suggestions;

                if (!query.trim().length) {
                    suggestions = [...customers];
                }
                else {
                    suggestions = customers.filter((customer) => {
                        return customer.nickname.toLowerCase().startsWith(query.toLowerCase());
                    });
                }

                setMultipleSuggestions(suggestions);
            }, 250);
        }
        else if (trigger === '#') {
            setTimeout(() => {
                const query = event.query;
                let suggestions;

                if (!query.trim().length) {
                    suggestions = [...tagSuggestions];
                }
                else {
                    suggestions = tagSuggestions.filter((tag) => {
                        return tag.toLowerCase().startsWith(query.toLowerCase());
                    });
                }

                setMultipleSuggestions(suggestions);
            }, 250);
        }
    }

    const itemTemplate = (suggestion) => {
        const src = 'https://primefaces.org/cdn/primereact/images/avatar/' + suggestion.representative.image;
        
        return (
            <div className="flex align-items-center">
                <img alt={suggestion.name} src={src}th="32" />
                <span className="flex flex-column ml-2">
                    {suggestion.name}
                    <small style={{ fontSize: '.75rem', color: 'var(--text-color-secondary)' }}>@{suggestion.nickname}</small>
                </span>
            </div>
        );
    }

    const multipleItemTemplate = (suggestion: any, options: MentionItemTemplateOptions) => {
        const trigger = options.trigger;

        if (trigger === '@' && suggestion.nickname) {
            return itemTemplate(suggestion);
        }
        else if (trigger === '#' && !suggestion.nickname) {
            return <span>{suggestion}</span>;
        }

        return null;
    }

    return (
        <div className="card flex justify-content-center">
            <Mention value={value} onChange={(e: React.ChangeEvent<HTMLTextAreaElement>) => setValue(e.target.value)} trigger={['@', '#']} suggestions={multipleSuggestions} onSearch={onMultipleSearch}
                field={['nickname']} placeholder="Enter @ to mention people, # to mention tag" itemTemplate={multipleItemTemplate} rows={5} cols={40} />
        </div>
    )
}
