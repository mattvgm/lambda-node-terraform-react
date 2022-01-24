import axios from "axios";
import React, { useCallback, useState } from "react";
import "./App.css";

function App() {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");

  const submitForm = useCallback(() => {
    axios
      .post("https://sszz4u4339.execute-api.us-east-1.amazonaws.com/dev/", {
        name,
        email,
      })
      .then((res) => {
        alert("Thank you for joining");
      })
      .catch((er) => {
        alert("Please try again");
      });
  }, [name, email]);
  return (
    <div className="App">
      <div id="outer">
        <div id="inner">
          <p>
            <h2>Subscribe to our newsletter</h2>
            We'll use lambda to register(pretty cool huh?!)
          </p>
          Name
          <input
            type="text"
            name="nameField"
            id="nameFieldId"
            onChange={(evt) => setName(evt.target.value)}
          />
          Email{" "}
          <input
            type="email"
            name="emailField"
            id="emailFieldId"
            onChange={(evt) => setEmail(evt.target.value)}
          />
          <button type="submit" onClick={submitForm}>
            Send
          </button>
        </div>
      </div>
    </div>
  );
}

export default App;
