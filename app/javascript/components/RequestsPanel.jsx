import React, { useState, useEffect } from "react";

function RequestCard({ request, onAccept, onReject, loading }) {
  const [showModal, setShowModal] = React.useState(false);

  const date = new Date(request.requested_at);
  const formattedDate = date.toLocaleDateString('en-GB', { 
    day: 'numeric', 
    month: 'long', 
    year: 'numeric' 
  });
  const formattedTime = date.toLocaleTimeString('en-US', { 
    hour: 'numeric', 
    minute: '2-digit', 
    hour12: true 
  });

  const initials = request.guest_name.split(' ')
    .map(n => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2);

  const handleAccept = () => {
    setShowModal(false);
    onAccept(request.id);
  };

  const handleReject = () => {
    setShowModal(false);
    onReject(request.id);
  };

  return (
    <>
      <article className="request-card">
        <div className="request-content">
          <div className="request-avatar">{initials}</div>
          <div className="request-details">
            <h3 className="request-name">{request.guest_name}</h3>
            <p className="request-meta">Online appointment</p>
            <div className="request-datetime">
              <span>📅 {formattedDate}</span>
              <span>🕒 {formattedTime}</span>
            </div>
          </div>
        </div>
        <button
          type="button"
          className="btn-text btn-answer"
          onClick={() => setShowModal(true)}
          disabled={loading}
        >
          Answer request
        </button>
      </article>

      {showModal && (
        <div className="react-modal-overlay" onClick={() => setShowModal(false)}>
          <div className="react-modal-dialog" onClick={(e) => e.stopPropagation()}>
            <div className="react-modal-header">
              <h3>Answer Request</h3>
              <button 
                className="react-modal-close" 
                onClick={() => setShowModal(false)}
              >
                ×
              </button>
            </div>
            <div className="react-modal-body">
              <p>Respond to {request.guest_name}'s appointment request :</p>
            </div>
            <div className="react-modal-footer">
              <button
                type="button"
                className="react-btn react-btn-secondary"
                onClick={handleReject}
                disabled={loading}
              >
                Reject
              </button>
              <button
                type="button"
                className="react-btn react-btn-primary"
                onClick={handleAccept}
                disabled={loading}
              >
                Accept
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}

export default function RequestsPanel({ nutritionistId, apiUrl }) {
  const [requests, setRequests] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [actionLoading, setActionLoading] = useState(false);

  const loadRequests = async () => {
    try {
      const response = await fetch(apiUrl);
      if (!response.ok) throw new Error("Failed to load");
      const data = await response.json();
      setRequests(data);
      setError(null);
    } catch (err) {
      setError("Error loading requests.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadRequests();
  }, []);

  const handleAction = async (id, action) => {
    setActionLoading(true);
    const url = `/api/nutritionists/${nutritionistId}/appointment_requests/${id}/${action}`;

    try {
      const response = await fetch(url, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
      });

      if (response.ok) {
        await loadRequests();
      } else {
        alert("Action failed. Please try again.");
      }
    } catch (err) {
      alert("Network error. Please try again.");
    } finally {
      setActionLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="empty-state">
        <p>Loading requests...</p>
      </div>
    );
  }

  if (error) {
    return <div className="flash flash-alert">{error}</div>;
  }

  if (requests.length === 0) {
    return (
      <div className="empty-state">
        <p>No pending requests.</p>
      </div>
    );
  }

  return (
    <div>
      {requests.map((request) => (
        <RequestCard
          key={request.id}
          request={request}
          onAccept={(id) => handleAction(id, "accept")}
          onReject={(id) => handleAction(id, "reject")}
          loading={actionLoading}
        />
      ))}
    </div>
  );
}
