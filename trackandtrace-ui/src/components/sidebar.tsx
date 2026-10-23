import styled from 'styled-components';
import { useNavigate, useLocation } from 'react-router-dom';

const SidebarWrapper = styled.div`
  width: 220px;
  min-height: 100vh;
  background: #fff;
  border-right: 1px solid #eee;
  padding: 24px 16px;
  flex-shrink: 0;
`;

const Logo = styled.div`
  font-size: 16px;
  font-weight: 500;
  color: #111;
  padding: 0 8px;
  margin-bottom: 32px;
  display: flex;
  align-items: center;
  gap: 8px;
`;

const NavItem = styled.div<{ $active?: boolean }>`
  padding: 10px 12px;
  border-radius: 6px;
  font-size: 14px;
  color: ${props => (props.$active ? '#0c447c' : '#555')};
  background: ${props => (props.$active ? '#e6f1fb' : 'transparent')};
  font-weight: ${props => (props.$active ? 500 : 400)};
  cursor: pointer;
  margin-bottom: 4px;

  &:hover {
    background: ${props => (props.$active ? '#e6f1fb' : '#f5f5f5')};
  }
`;

function Sidebar() {
  const navigate = useNavigate();
  const location = useLocation();

  return (
    <SidebarWrapper>
      <Logo> Track & Trace</Logo>
      <NavItem $active={location.pathname === '/'} onClick={() => navigate('/')}>
        Order search
      </NavItem>
    </SidebarWrapper>
  );
}

export default Sidebar;