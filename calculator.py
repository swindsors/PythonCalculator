import streamlit as st
import math

def main():
    st.title("🧮 Simple Calculator")
    st.write("A simple calculator built with Streamlit")
    
    # Create tabs for different calculator modes
    tab1, tab2 = st.tabs(["Basic Calculator", "Scientific Calculator"])
    
    with tab1:
        st.header("Basic Operations")
        
        # Input fields
        col1, col2, col3 = st.columns([2, 1, 2])
        
        with col1:
            num1 = st.number_input("First Number", value=0.0, format="%.2f")
        
        with col2:
            operation = st.selectbox(
                "Operation",
                ["+", "-", "×", "÷"],
                index=0
            )
        
        with col3:
            num2 = st.number_input("Second Number", value=0.0, format="%.2f")
        
        # Calculate button
        if st.button("Calculate", type="primary"):
            try:
                if operation == "+":
                    result = num1 + num2
                elif operation == "-":
                    result = num1 - num2
                elif operation == "×":
                    result = num1 * num2
                elif operation == "÷":
                    if num2 == 0:
                        st.error("Error: Division by zero is not allowed!")
                        return
                    result = num1 / num2
                
                st.success(f"Result: {num1} {operation} {num2} = {result}")
                
            except Exception as e:
                st.error(f"An error occurred: {str(e)}")
    
    with tab2:
        st.header("Scientific Operations")
        
        col1, col2 = st.columns(2)
        
        with col1:
            st.subheader("Single Number Operations 1")
            number = st.number_input("Enter Number", value=0.0, format="%.4f", key="sci_num")
            
            sci_operation = st.selectbox(
                "Choose Operation",
                ["Square Root", "Square", "Cube", "Sine", "Cosine", "Tangent", "Natural Log", "Log Base 10"]
            )
            
            if st.button("Calculate Scientific", type="primary"):
                try:
                    if sci_operation == "Square Root":
                        if number < 0:
                            st.error("Cannot calculate square root of negative number!")
                        else:
                            result = math.sqrt(number)
                            st.success(f"√{number} = {result}")
                    
                    elif sci_operation == "Square":
                        result = number ** 2
                        st.success(f"{number}² = {result}")
                    
                    elif sci_operation == "Cube":
                        result = number ** 3
                        st.success(f"{number}³ = {result}")
                    
                    elif sci_operation == "Sine":
                        result = math.sin(math.radians(number))
                        st.success(f"sin({number}°) = {result}")
                    
                    elif sci_operation == "Cosine":
                        result = math.cos(math.radians(number))
                        st.success(f"cos({number}°) = {result}")
                    
                    elif sci_operation == "Tangent":
                        result = math.tan(math.radians(number))
                        st.success(f"tan({number}°) = {result}")
                    
                    elif sci_operation == "Natural Log":
                        if number <= 0:
                            st.error("Natural log is only defined for positive numbers!")
                        else:
                            result = math.log(number)
                            st.success(f"ln({number}) = {result}")
                    
                    elif sci_operation == "Log Base 10":
                        if number <= 0:
                            st.error("Logarithm is only defined for positive numbers!")
                        else:
                            result = math.log10(number)
                            st.success(f"log₁₀({number}) = {result}")
                
                except Exception as e:
                    st.error(f"An error occurred: {str(e)}")
        
        with col2:
            st.subheader("Power Operations")
            base = st.number_input("Base", value=2.0, format="%.2f")
            exponent = st.number_input("Exponent", value=2.0, format="%.2f")
            
            if st.button("Calculate Power"):
                try:
                    result = base ** exponent
                    st.success(f"{base}^{exponent} = {result}")
                except Exception as e:
                    st.error(f"An error occurred: {str(e)}")
    
    # History section
    st.markdown("---")
    st.subheader("Calculator Features")
    
    col1, col2, col3 = st.columns(3)
    
    with col1:
        st.info("✅ Basic arithmetic operations")
        st.info("✅ Scientific functions")
    
    with col2:
        st.info("✅ Error handling")
        st.info("✅ User-friendly interface")
    
    with col3:
        st.info("✅ Multiple calculation modes")
        st.info("✅ Real-time results")

if __name__ == "__main__":
    main()
