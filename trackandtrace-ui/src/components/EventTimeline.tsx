
import type { OrderEventResult } from "../viewmodel/order.types";
import styled from "styled-components";

interface EventTimelineProps {
    events: OrderEventResult[];
}

const TimelineWrapper = styled.div`
    display: flex;
    flex-direction: column;
`;

const EventItem = styled.div`
  display: flex;
  gap: 12px;
  margin-bottom: 20px;

  &:last-child {
    margin-bottom: 0;
  }
`;

const DotColumn = styled.div`
  display: flex;
  flex-direction: column;
  align-items: center;
`;

const Dot = styled.div`
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: #378add;
  flex-shrink: 0;
  margin-top: 4px;
`;

const Line = styled.div`
  width: 1px;
  background: #ddd;
  flex: 1;
  margin-top: 4px;
  min-height: 20px;
`;

const EventContent = styled.div``;

const EventDescription = styled.p`
  font-size: 13px;
  font-weight: 500;
  color: #333;
  margin-bottom: 2px;
`;

const EventMeta = styled.p`
  font-size: 12px;
  color: #888;
`;

function EventTimeline({ events }: EventTimelineProps) {
    if (events.length === 0) {
        return <p style={{ color: '#888', fontSize: '13px' }}>No events found.</p>;
    }
    return (
        <TimelineWrapper>
            {events.map((event, index) => (
                <EventItem key={index}>
                    <DotColumn>
                        <Dot />
                        {index < events.length - 1 && <Line />}
                    </DotColumn>
                    <EventContent>
                        <EventDescription>{event.eventDescription}</EventDescription>
                        <EventMeta>
                            {event.eventCode} ·{' '}
                            {event.eventTimestamp
                                ? new Date(event.eventTimestamp).toLocaleString()
                                : '-'}{' '}
                            {event.location && `· ${event.location}`}
                        </EventMeta>
                    </EventContent>
                </EventItem>
            ))}
        </TimelineWrapper>
    );
}

export default EventTimeline;
