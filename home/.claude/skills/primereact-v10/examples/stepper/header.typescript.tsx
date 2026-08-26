import { useRef } from 'react';
import { Stepper } from 'primereact/stepper';
import { StepperPanel } from 'primereact/stepperpanel';
import { Button } from 'primereact/button';

export default function BasicDemo() {
    const stepperRef = useRef(null);

    return (
        <h5>Position top</h5>
        <Stepper ref={(ref) => (stepperRef.current[2] = ref)} headerPosition="top">
            <StepperPanel header="Header I"></StepperPanel>
            <StepperPanel header="Header II"></StepperPanel>
            <StepperPanel header="Header III"></StepperPanel>
        </Stepper>
        <h5>Position right</h5>
        <Stepper ref={(ref) => (stepperRef.current[0] = ref)} headerPosition="right">
            <StepperPanel header="Header I"></StepperPanel>
            <StepperPanel header="Header II"></StepperPanel>
            <StepperPanel header="Header III"></StepperPanel>
        </Stepper>
        <h5>Position left</h5>
        <Stepper ref={(ref) => (stepperRef.current[1] = ref)} headerPosition="left">
            <StepperPanel header="Header I"></StepperPanel>
            <StepperPanel header="Header II"></StepperPanel>
            <StepperPanel header="Header III"></StepperPanel>
        </Stepper>
        <h5>Position bottom</h5>
        <Stepper ref={(ref) => (stepperRef.current[2] = ref)} headerPosition="bottom">
            <StepperPanel header="Header I"></StepperPanel>
            <StepperPanel header="Header II"></StepperPanel>
            <StepperPanel header="Header III"></StepperPanel>
        </Stepper>
    );
}
