
import { createGlobalStyle } from "styled-components";


const GlobalStyles = createGlobalStyle`
  * {
    margin: 0;
    padding: 0;
  }

  html, body, #root {
    width: 100%;
    min-height: 100vh;
  }

    body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
    background-color: #f5f5f5;
    color: #333;
    font-size: 14px;
    line-height: 1.5;
  }

  table {
    border-collapse: collapse;
    width: 100%;
  }

  button {
    cursor: pointer;
    font-family: inherit;
  }

  input, select {
    font-family: inherit;
  }
`;

export default GlobalStyles;