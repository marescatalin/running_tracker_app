import { LineChart } from "@mui/x-charts";
import Message from "./Message";
import { useEffect, useState } from "react";
import axios from "axios";

export interface DataEntryPoint {
  date: string;
  distance: string;
}

function App() {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  
  useEffect(() => {
    axios
        .get("/api/distance"
        )
        .then((response) => {
            setData(response.data);
            setLoading(false);
        })
        .catch((err) => {
            setError(err.message);
            setLoading(false);
        });
}, []);

  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error in the proxy request to backend api: {error}</div>;

  let x: string[] = []
  let y: number[] = []

  data.forEach(data => {
    const response = data as DataEntryPoint;
    x.push(response.date)
    y.push(Number(response.distance))
  })

  return (
    <>
    <Message message="Catalin"></Message>
    <LineChart
      xAxis={[{ 
        scaleType: "point",
        data: x }]}
      series={[
        {
          data: y,
        },
      ]}
      height={200}
    />
    </>
  );
  
}

export default App;



