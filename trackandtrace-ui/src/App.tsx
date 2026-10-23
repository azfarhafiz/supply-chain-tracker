import { useState } from 'react'
import './App.css'
import { BrowserRouter, Route, Routes } from 'react-router-dom'
import Search from './pages/Search';
import OrderDetail from './pages/OrderDetail';
import GlobalStyles from './styles/GlobalStyles'
import styled from 'styled-components'
import Sidebar from './components/sidebar'

const Layout = styled.div`
  display: flex;
  background-color: #e4dfdf;
`;

function App() {
  const [count, setCount] = useState(0)

  return (
    <BrowserRouter>
      <GlobalStyles />
      <Layout>
        <Sidebar />
        <Routes>
          <Route path="/" element={<Search />} />
          <Route path="/orders/:ref" element={<OrderDetail />} />

        </Routes>
      </Layout>


    </BrowserRouter>
  )
}

export default App
