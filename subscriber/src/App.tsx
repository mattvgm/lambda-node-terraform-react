import axios from "axios";
import React, { useCallback, useState } from "react";
import "./App.css";

const ENDPOINT_URL = "http://url.com/dev/";

function App() {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");

  const submitForm = useCallback(() => {
    axios
      .post(ENDPOINT_URL, {
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
            <h1>Subscribe to our newsletter ✉️</h1>
            We'll use lambda to register your email into a DynamoDB table(pretty
            cool huh?!)
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
          <p>
            <i>
              <a href="https://github.com/busycore/lambda-node-terraform-react">
                You can get the <b>WHOLE</b> source code here 💻
              </a>
            </i>
          </p>
          <p>
            <i className="footerMessage">Made with ❤️ by Matheus</i>
          </p>
        </div>
      </div>
    </div>
  );
}

export default App;
