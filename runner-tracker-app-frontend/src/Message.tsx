interface Prop {
    message: string
}

function Message ({ message }: Prop) {
    // JSX: Javascript XML, will get converted to javascript
    return <h1>Hello {message}, here is your running progress for this year!</h1>;
}

export default Message;